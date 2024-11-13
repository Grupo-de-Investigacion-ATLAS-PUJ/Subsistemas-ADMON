import sympy
import re

class FX_cmp_2():

    def __init__(self) -> None:
        self.val_err = False
        self.str_err = False
        self.potential_error = 0

    def check(self, structur1, structur2):
        f1 = structur1["eq"]
        f2 = structur2["eq"]
        if f1 != None and f2 != None:
            f1 = sympy.sympify(f1)
            f2 = sympy.sympify(f2)
            if sympy.sympify(f1-f2) == 0:
                str_err = False
            else:
                str_err = True

        if not str_err:
            f1 = [x for x in re.split(f"(log\()|(pow\()|(\+)|((?<!e)\-)|(\*)|(\/)|(\()|(\))|(,[0-9])", structur1["eq"]) if x]
            f2 = [x for x in re.split(f"(log\()|(pow\()|(\+)|((?<!e)\-)|(\*)|(\/)|(\()|(\))|(,[0-9])", structur2["eq"]) if x]
            var_f1=[]
            var_f2=[]
            for x, y in zip(f1, f2):
                if x in structur1 and type(structur1[x]) is not dict:
                    if not re.match(r"\$\_\.TPDO3\.ch[0-9][0-9]?\.value", structur1[x]):
                        f1[f1.index(x)] = x.replace(x, structur1[x])
                elif x in structur1 and type(structur1[x]) is dict:
                    var_f1.append(x)
                if y in structur2 and type(structur2[y]) is not dict:
                    if not re.match(r"\$\_\.TPDO3\.ch[0-9][0-9]?\.value", structur2[y]):
                        f2[f2.index(y)] = y.replace(y, structur2[y])
                elif y in structur2 and type(structur2[y]) is dict:
                    var_f2.append(y)
            f1 = sympy.sympify("".join(f1))
            f2 = sympy.sympify("".join(f2))
            if sympy.sympify(f1-f2) == 0:
                return False, str_err, var_f1, var_f2
            else:
                return True, str_err, var_f1, var_f2
        else:
            return True, str_err, [], []

    def data_in(self, in1, in2, sub_f1=[], sub_f2=[]):
        val_err, str_err, sub_f1, sub_f2 = self.check(in1, in2)
        if val_err and not str_err:
            in1["ERROR"] = "VAR"
            in2["ERROR"] = "VAR"
            self.val_err = True
        if not str_err:
            for var1, var2 in zip(sub_f1, sub_f2):
                res1, res2, = self.data_in(in1[var1], in2[var2])
                in1[var1].update(res1)
                in2[var2].update(res2)
        else:
            in1["ERROR"] = "EQ"
            in2["ERROR"] = "EQ"
            self.str_err = True
        return in1, in2