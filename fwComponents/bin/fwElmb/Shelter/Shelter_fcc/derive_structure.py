import re

class fx_to_dict():

    def __init__(self, fx_ng, fx_og) -> None:

        self.str_ng = fx_ng
        self.str_og = fx_og
        self.dict_ng = dict()
        self.dict_og = dict()
        self.colstr_ng = str()
        self.colstr_og = str()
        self.res = (bool, bool)
    
    def color_it(self):
        self.colstr_ng = self.build_back_colored(self.dict_ng)
        self.colstr_og = self.build_back_colored(self.dict_og)

    def derive_structure(self):
        self.dict_ng, res = self.sub_structure(self.str_ng)
        self.dict_og, res = self.sub_structure(self.str_og)
    
    def is_nested(self, istr):
        if istr.startswith(('(','log(','pow(')) and istr.endswith(')'):
            return True
    
    def grab_inner_stuff(self, istr):
        split = [x for x in re.split(f"^log\(|^pow\(|^\(|\)?$|,3\)$", istr) if x]
        content = "".join(split)
        return content, istr
    
    def create_regex_pattern(self, istr , p_list):
        pattern = ''
        even_cnt = 0
        total_cnt = 0
        for element in istr:
            if element == '(': 
                even_cnt += 1
                total_cnt += 1
                pattern += '[log|pow]*\('
            elif element == ')':
                even_cnt += -1
                pattern += '\)'
                if even_cnt == 0:
                    break
            elif re.findall(r'(\\[(|)])$', pattern):
                pattern += '[^()]*'
        if pattern != "":
            p_list.append(pattern)
            rstr = istr.replace(re.search(pattern, istr).group(), '', 1)
            self.create_regex_pattern(rstr, p_list)
        else:
            return p_list
        return p_list

    def sub_structure(self, i_str):
        dict = {}
        cnt = 0
        operators = '(\+)|((?<!e)\-)|(\*)|(\/)'
        pattern = []
        pattern = self.create_regex_pattern(i_str, pattern)
        regex_command = "|".join(pattern)

        if pattern:
            split = [x for x in re.split(f"({regex_command})|{operators}", i_str) if x]
        else:
            split = [x for x in re.split(f"{operators}", i_str) if x]
        
        for element in split:
            if not re.match(operators, element):
                if re.match(r"TPDO3\.Value\_[0-9][0-9]?", element):
                    replacement = re.sub(r"TPDO3\.Value\_", "$_.TPDO3.ch", element)
                    replacement += ".value"
                    dict[f"var_{cnt}"] = replacement
                else:
                    dict[f"var_{cnt}"] = element
                split[split.index(element)] = element.replace(element, f"var_{cnt}")
                cnt += 1
        
        for sub in dict:
            if self.is_nested(dict[sub]):
                inner_content, xy = self.grab_inner_stuff(dict[sub])
                ng = [x for x in re.split(f"^log\(|^pow\(|^\(|\)$|,3\)$", dict[sub]) if x]
                ng = "".join(ng)
                dict[sub], subs = self.sub_structure(inner_content)
                if not re.match(f"^\(", xy):
                    xy = xy.replace(ng, subs)
                else:
                    xy = subs
                dict[sub]["eq"] = xy
        
        res = "".join(split)
        dict[f"eq"] = "".join(split)
        return dict, res

    def build_back_colored(self, i_dict):
        err_state = None
        for element in i_dict:
            if element is "eq":
                eq = i_dict[element]
        eq = [x for x in re.split(r"(^pow\()|(^log\()|(\+)|((?<!e)\-)|(\*)|(\/)|(\)$)|(,[0-9])", eq) if x]
        if "ERROR" in i_dict:
            if i_dict["ERROR"] == "EQ":
                err_state = True
        for element in eq:
            if "var_" in element:
                if type(i_dict[element]) is dict:
                    sub = self.build_back_colored(i_dict[element])
                    if not re.match(r"(^pow\()|(^log\()", sub):
                        sub = "(" + sub + ")"
                    eq[eq.index(element)] = element.replace(element, sub)
                else:
                    if "ERROR" in i_dict:
                        if i_dict["ERROR"] == "VAR":
                            replacement = '<span style=\"color: #0000FF\">' + i_dict[element] + '</span>' 
                            eq[eq.index(element)] = element.replace(element, replacement)
                        else:
                            eq[eq.index(element)] = element.replace(element, i_dict[element])
                    else:
                        eq[eq.index(element)] = element.replace(element, i_dict[element])
        eq = "".join(eq)
        if err_state:
            eq = '<span style=\"color: #ff0000\">' + eq + '</span>' 
        return eq

if __name__ == '__main__':
    pass