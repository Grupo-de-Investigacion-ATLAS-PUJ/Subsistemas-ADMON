import re
import sympy
import itertools
from collections import Counter

class FX_cmp():

    def __init__(self) -> None:
        self.val_err = False
        self.str_err = False
        self.potential_error = 0

    def find_nested_variables(self, structur1, structur2):
        f1 = [x for x in re.split(f"log\(|pow\(|\+|(?<!e)\-|\*|\/|\)|,[0-9]", structur1["eq"]) if x]
        f2 = [x for x in re.split(f"log\(|pow\(|\+|(?<!e)\-|\*|\/|\)|,[0-9]", structur2["eq"]) if x]
        var_f1 = []
        var_f2 = []
        for var in f1:
            if var in structur1:
                if type(structur1[var]) is dict:
                    var_f1.append(var)
        for var in f2:
            if var in structur2:
                if type(structur1[var]) is dict:
                    var_f2.append(var)
        return var_f1, var_f2
    
    def check_constants(self, structur1, structur2):
        f1 = [x for x in re.split(f"(\+)|((?<!e)\-)|(\*)|(\/)|(\()|(\))", structur1["eq"]) if x]
        f2 = [x for x in re.split(f"(\+)|((?<!e)\-)|(\*)|(\/)|(\()|(\))", structur2["eq"]) if x]
        for var in f1:
            if var in structur1 and type(structur1[var]) is not dict:
                if not re.match(r"\$\_\.TPDO3\.ch[0-9][0-9]?\.value", structur1[var]):
                    f1[f1.index(var)] = var.replace(var, structur1[var])
        f1 = "".join(f1)
    
        for var in f2:
            if var in structur2 and type(structur2[var]) is not dict:
                if not re.match(r"\$\_\.TPDO3\.ch[0-9][0-9]?\.value", structur2[var]):
                    f2[f2.index(var)] = var.replace(var, structur2[var])
        f2 = "".join(f2)
        eq1 = sympy.sympify(f1)
        eq2 = sympy.sympify(f2)
        if sympy.sympify(eq1-eq2) == 0:
            return True
        else:
            return False

    def check_structure(self, structur1, structur2):
        envelop_f1 = re.match(r"^log\(|^pow\(", structur1["eq"])
        envelop_f2 = re.match(r"^log\(|^pow\(", structur2["eq"])

        if (envelop_f1 and envelop_f2):
            if envelop_f1.group() != envelop_f2.group():
                return False
        elif not envelop_f1 and envelop_f2:
            return False
        elif envelop_f1 and not envelop_f2:
            return False
        try:
            f1 = sympy.sympify(structur1["eq"])
            f2 = sympy.sympify(structur2["eq"])
            if sympy.sympify(f1-f2) == 0:
                return True
            else:
                return False
        except:
            return False

    def compare(self, in1, in2, rec_depth=None):
        if self.check_structure(in1, in2):
            if rec_depth is None: rec_depth = 0
            rec_depth += 1
            if not self.check_constants(in1, in2):
                in1["ERROR"] = "VAR"
                in2["ERROR"] = "VAR"
                self.val_err = True
                #self.cnt['var_err'] += 1
            nest_f1, nest_f2 = self.find_nested_variables(in1, in2)
            successfull_tested_f1 = []
            successfull_tested_f2 = []
            for r in itertools.product(nest_f1, nest_f2): 
                if r[0] not in successfull_tested_f1 and r[1] not in successfull_tested_f2:
                    res = self.compare(in1[r[0]], in2[r[1]], rec_depth)
                    if res:
                        nest_f1.remove(r[0])
                        nest_f2.remove(r[1])
            if nest_f1 or nest_f2:
                self.str_err = True
            for element in nest_f1:
                in1[element]["ERROR"] = "EQ"
                #in1[element] = (in1[element], False)
                #print(in1[element])
            for element in nest_f2:
                in2[element]["ERROR"] = "EQ"
                #print(in2[element])
                #print()
        else:
            if rec_depth is None:
                in1["ERROR"] = "EQ"
                in2["ERROR"] = "EQ"
                self.str_err = True
            return False
        return True
