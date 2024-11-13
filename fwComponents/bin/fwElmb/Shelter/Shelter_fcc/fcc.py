from lxml import etree as et
import logging
import re
import copy
import progressbar
from collections import Counter
from sympy import false
from Shelter_fcc.fx_compare import FX_cmp
from Shelter_fcc.derive_structure import fx_to_dict
from Shelter_fcc.create_html import print_pretty_results
from Shelter_fcc.fx2_compare import FX_cmp_2

class cross_check(print_pretty_results):

    def __init__(self) -> None:
        self.output = print_pretty_results()
        self.cnt = Counter()

        self.logger = logging.getLogger('CCT\FCC')
        self.logger.setLevel(logging.DEBUG)

    def empty_formular_check(self, ng_eq, channel):
        ng_eq = ''.join(ng_eq.split(" "))
        if ng_eq == f"$_.TPDO3.ch{channel}.value":
            self.cnt['correct'] += 1
            return True
        else:
            print(ng_eq, channel)
            self.cnt['str_err'] += 1
            return 'Fai_error'

    def create_node_dict(self, arg_input):
        parser = et.XMLParser(resolve_entities=False)
        ng_root = et.parse(arg_input, parser).getroot()
        namespace = re.match(r'\{.*\}', ng_root.tag)

        if namespace is None:
            namespace = ""
        else:
            namespace = namespace.group(0)
            
        fdict = {}
        fcount = 0
        for bus in ng_root:
            if bus.tag == namespace + "Bus" or bus.tag == "CANBUS":
                bus_dict = {}
                for node in bus:
                    if node.tag == namespace + "Node" or (node.tag == "NODE" and node.get('type') == "ELMB"):
                        node_dict = {}
                        for calc_var in node:
                            if calc_var.tag == namespace + 'CalculatedVariable' or calc_var.tag == 'ITEM':
                                node_dict[calc_var.get('name')] = calc_var.get('value')
                                fcount += 1
                        if namespace is not "":
                            bus_dict[(node.get('name'), int(node.get('id')))] = node_dict
                        else:
                            bus_dict[(node.get('name'), int(node.get('nodeid')))] = node_dict
                fdict[(bus.get('name'), bus.get('port'))] = bus_dict
        return fdict, fcount

    def fcc(self, ng_eq, og_eq, fx2):
        try:
            ng_eq = ''.join(ng_eq.split(" "))
            og_eq = ''.join(og_eq.split(" "))

            drain = fx_to_dict(ng_eq, og_eq)
            drain.derive_structure()
            fx2.val_err = False
            fx2.str_err = False
            fx2.data_in(drain.dict_ng, drain.dict_og)
            drain.res = (fx2.val_err, fx2.str_err)
            if fx2.val_err:
                self.cnt['var_err'] += 1
            if fx2.str_err:
                self.cnt['str_err'] += 1
            if fx2.val_err and fx2.str_err:
                self.cnt['combined'] += 1
            if not fx2.val_err and not fx2.str_err:
                self.cnt['correct'] += 1
                
            if fx2.val_err or fx2.str_err:
                drain.color_it()
                ng_eq = drain.colstr_ng
                og_eq = drain.colstr_og
            else:
                return True
            return drain
        except Exception as e:
            print(e)
            return None

    def start_fcc(self, ng_in, og_in, output, project):
        self.cnt = Counter()
        ng_dict, formular_count_ng = self.create_node_dict(ng_in)
        og_dict, formular_count_og = self.create_node_dict(og_in)

        self.logger.info(f"Project: {project} Elements to compare: {formular_count_ng}")
        self.logger.info(f"Elements to compare NG: {formular_count_ng}")
        self.logger.info(f"Elements to compare OG: {formular_count_og}")

        if formular_count_ng == 0 and formular_count_og == 0:
            raise Exception('Nothing to compare')
        elif formular_count_ng == 0 and formular_count_og > 0:
            raise Exception('NG-file is empty')
        elif formular_count_ng > 0 and formular_count_og == 0:
            raise Exception('OG-file is empty')
            
        result_dict = copy.deepcopy(ng_dict)

        fx2 = FX_cmp_2()
        comparing_error = 0
        err_log = []
        for bus in ng_dict:
            for og_bus in og_dict:
                if bus[0] == og_bus[0]:
                    for node in ng_dict[bus]:
                        if node in og_dict[og_bus]:
                            for calcvar in ng_dict[bus][node]:
                                if calcvar in og_dict[og_bus][node]:
                                    result_dict[bus][node][calcvar] = self.fcc(ng_dict[bus][node][calcvar], og_dict[og_bus][node][calcvar], fx2)
                                    if result_dict[bus][node][calcvar] == None:
                                        comparing_error += 1
                                elif re.fullmatch(r"ai_[0-9][0-9]?", calcvar):
                                    result_dict[bus][node][calcvar] = self.empty_formular_check(ng_dict[bus][node][calcvar], re.search(r"[0-9][0-9]?", calcvar).group(0))
                                else:
                                    result_dict[bus][node][calcvar] = False
                                    self.logger.warning(f"Calcvar {calcvar} not found in OG file")
                        else:
                            for og_node in og_dict[og_bus]:
                                if og_node[0] == node[0]:
                                    if og_node[1] != node[1]:
                                        self.logger.error(f"Crucial ERROR - Node {node[0]} is associated to different Node IDs within both files")
                                        err_log.append(f"Crucial ERROR - Node {node[0]} is associated to different Node IDs within both files")
                                        result_dict[bus][node] = {}
                                elif og_node[1] == node[1]:
                                    if og_node[0] != node[0]:
                                        self.logger.error(f"Crucial ERROR - Node ID {node[1]} is associated to different ELMBs within both files")
                                        err_log.append(f"Crucial ERROR - Node ID {node[1]} is associated to different ELMBs within both files")
                                        result_dict[bus][node] = {}
                            self.logger.warning(f"There is no matching entry to Node {node} in the OG file - Please check LOG")
                            err_log.append(f"There is no matching entry to Node {node} in the OG file - Please check LOG")
                            result_dict[bus][node] = {}

        for bus in ng_dict:
            if not bus in og_dict:
                exists = False
                for og_bus in og_dict:
                    if og_bus[0] == bus[0] and og_bus[1] != bus[1]:
                        self.logger.error(f"ERROR - Bus {bus[0]} is associated to different Ports within both files (OG: {og_bus[1]}, NG: {bus[1]})")
                        err_log.append(f"ERROR - Bus {bus[0]} is associated to different Ports within both files (OG: {og_bus[1]}, NG: {bus[1]})")
                        exists = True
                    elif og_bus[1] == bus[1] and og_bus[0] != bus[0]:
                        self.logger.error(f"ERROR - Port {bus[1]} is associated to different Port Names within both files (OG: {og_bus[0]}, NG: {bus[0]})")
                        err_log.append(f"ERROR - Port {bus[1]} is associated to different Port Names within both files (OG: {og_bus[0]}, NG: {bus[0]})")
                if not exists:
                    self.logger.warning(f"There is no matching entry to Bus {bus} in the OG file - Please check DP file")
                    err_log.append(f"There is no matching entry to Bus {bus} in the OG file - Please check DP file")
                    result_dict[bus] = {}
        
        self.logger.warning(f"Potential crucial ERRORS during fcc of {project}: {comparing_error}")
        err_log.append(f"Potential crucial ERRORS during fcc of {project}: {comparing_error}")

        for bus in list(result_dict.keys()):
            for node in list(result_dict[bus].keys()):
                for calcvar in list(result_dict[bus][node].keys()):
                    if result_dict[bus][node][calcvar] is True:
                        del result_dict[bus][node][calcvar]
        self.output.generate_html_output(result_dict, project, self.cnt, formular_count_ng, output, ng_dict, og_dict, err_log)