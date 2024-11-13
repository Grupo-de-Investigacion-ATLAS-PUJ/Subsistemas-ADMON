from enum import IntEnum, unique
import logging
import re
import pdb

@unique
class DpAttrMode(IntEnum):
    DPATTR_ADDR_MODE_UNDEFINED = 0
    DPATTR_ADDR_MODE_OUTPUT = 1
    DPATTR_ADDR_MODE_INPUT_SPONT = 2
    DPATTR_ADDR_MODE_INPUT_SQUERY = 3
    DPATTR_ADDR_MODE_INPUT_POLL = 4
    DPATTR_ADDR_MODE_OUTPUT_SINGLE = 5
    DPATTR_ADDR_MODE_IO_SPONT = 6
    DPATTR_ADDR_MODE_IO_POLL = 7
    DPATTR_ADDR_MODE_IO_SQUERY = 8

class OpcUaPeripheralAddress():
    '''Peripheral address loaded from the DPL'''
    def __init__(self, line):
        (manager, dpe_name, type_name, addr_type, addr_ref, addr_pg, addr_conn, addr_os, addr_si, addr_dir, addr_int, addr_low, addr_act, addr_st, addr_iv, addr_rep, addr_dt, addr_drv) = line.split('\t')
        addr_ref_split = addr_ref.rstrip('"').lstrip('"').split('$')
        self.opcua_server = addr_ref_split[0]
        self.opcua_subscription = addr_ref_split[1]
        self.opcua_address_str = addr_ref_split[4]
        addr_dir_int = int(addr_dir[1:]) # let's skip the backslash
        old_new_comparison = addr_dir_int & 16 # TODO not used presently
        self.addr_mode = DpAttrMode(addr_dir_int & 0x0f)
    
    def __str__(self):
        return self.opcua_address_str


class DataPointElement:
    def __init__(self, name):
        # pdb.set_trace()
        self.name = name
        self.orig_value = None
        self.addr_ref = None

    def __repr__(self):
        return f'DPE orig:{self.orig_value}, addr:{self.addr_ref}'

class DataPoint:
    def __init__(self, name, dpt_as_str, dp_id):
        self.name = name
        self.dpt_as_str = dpt_as_str
        self.dp_id = dp_id
        self.whereabouts = {}
        self.dpes = {}

    def __str__(self):
        return self.name

    def __repr__(self):
        return f'DP name={str(self)}'

class AsciiLoader:
    def __init__(self, path):
        self.og_addr = str()
        self.lines = open(path, 'r', encoding='iso8859-1').read().splitlines()
        section_ids = {
            '# DpType': 'DPT',
            '# Datapoint/DpId': 'DP',
            '# Aliases/Comments': 'AC',
            '# PeriphAddrMain': 'AD',
            '# DpValue': 'DPV'}
        self.section_info = {} # the output
        logging.info(f'{path}: {len(self.lines)} lines loaded')
        current_line_no = 0
        current_section_type = None
        current_section_start_line = None
            
        while current_line_no < len(self.lines):
            end_line_no = AsciiLoader.find_end_line_number(self.lines, current_line_no)
            if end_line_no != current_line_no:
                logging.warning(f'Skipping multi-line from line {current_line_no} to {end_line_no}')
                current_line_no = end_line_no+1
                continue
            line = self.lines[current_line_no]
            if line == '':
                next_line = self.lines[current_line_no+1]
                if current_section_type != None and next_line[0] == '#':
                    print(f'Ending section {current_section_type}, end line is {current_line_no}')
                    self.section_info[current_section_type] = (current_section_start_line+2, current_line_no-1)
                    current_section_type = None   
                current_line_no += 1
                continue
            if line[0] == '#':
                if line in section_ids.keys():
                    current_section_type = section_ids[line]
                    current_section_start_line = current_line_no
                else:
                    logging.warning(f'Section type not supported: {line}')
            current_line_no += 1


    def find_end_line_number(lines, start_line_no):
        '''Handle annoying multi-line strings... '''
        balanced_overall = True
        line_no = start_line_no
        while True:
            try:
                line = lines[line_no]
            except:
                print("Fatal: while trying to find a matching last line, failed to read line "+str(start_line_no))
                exit(-1)
            line_is_balanced = (line.count('"')-line.count("\"")) % 2 == 0
            if not line_is_balanced:
                balanced_overall = not balanced_overall
            if balanced_overall:
                break
            line_no += 1
            # TODO? what if we hit the end?
        return line_no

    def loadDataPoints(self):
        dps = []
        (line_no, end_line_no) = self.section_info['DP']
        for line in self.lines[line_no:end_line_no+1]:
            (dp_name, dp_type, dp_id) = line.split('\t')
            dp = DataPoint(dp_name, dp_type, dp_id)
            dps.append(dp)
        logging.info(f'{len(dps)} DPs loaded')
        return dps

    def loadAliasesAndComments(self, dps):
        '''dps is a list of DataPoint, for instance returned by loadAliasesAndComments'''
        (line_no, end_line_no) = self.section_info['AC']
        comment_re = re.compile(r'lt:\d+ LANG:\d+ "([^"]+)')
        for line in self.lines[line_no:end_line_no]:
            try:
                (x_name, something1, lt_lang_str) = line.split('\t')
                match = comment_re.match(lt_lang_str)
                if match:
                    first_dot_pos = x_name.find('.')
                    dp_name = x_name[:first_dot_pos]
                    post_dp_name = x_name[first_dot_pos+1:]
                    matching_dps = [dp for dp in dps if dp.name == dp_name]
                    if len(matching_dps) == 1:
                        dp = matching_dps[0]
                    else:
                        print(f'Not able to find the DP {dp_name}, skipping')
                        continue
                    comment = match.groups()[0]
                    if post_dp_name == '': # DP
                        dp.comment = comment
                    else:
                        if post_dp_name in dp.dpes:
                            pass # TODO
                        else:
                            # print(f'Implicitly creating DPE for loading comment, {dp_name} {post_dp_name}')
                            dpe = DataPointElement(post_dp_name)
                            dpe.comment = comment
                            dpe.whereabouts = {'origin' : 'implicit_from_comment'}
                            dp.dpes[post_dp_name] = dpe


            except Exception as e:
                print(f'Failed to load comments for this line: {line}')

    def loadValues(self, dps):
        (line_no, end_line_no) = self.section_info['DPV']
        print (self.section_info['DPV'])
        for counter, line in enumerate(self.lines[line_no:end_line_no+1]):
            try:
                abs_line_no = counter + line_no
                (manager, dpe_name, type_name, orig_value, orig_status, orig_stime) = line.split('\t')
                
                #print("manager = " + manager)
                #print("dpe_name = " + dpe_name)
                #print("tpye_name = " + type_name)
                #print("orig_value = " + orig_value)
                #print("orig_status = " + orig_status)
                #print("orig_stime = " + orig_stime)
                first_dot_pos = dpe_name.find('.')
                dp_name = dpe_name[:first_dot_pos]
                # if dp_name[0] == '_':
                #    # continue # skip internal DPs for now
                #print(f'(L {abs_line_no} Loading value for DPE {dpe_name}, DP {dp_name}')
                matched_dps = [dp for dp in dps if dp.name == dp_name]
                if len(matched_dps) != 1:
                    logging.error(f'Cant find DP {dp_name} (matched len was {len(matched_dps)})')
                    continue
                dp = matched_dps[0]
                post_dp_name = dpe_name[first_dot_pos+1:]
                if not post_dp_name in dp.dpes:
                    #print(f'Implicitly attaching the dpe {post_dp_name}')
                    dp.dpes[post_dp_name] = DataPointElement(post_dp_name)
                dp.dpes[post_dp_name].orig_value = orig_value
                #print(f'set value {orig_value} on dp {dp.name}, dpe {post_dp_name}')
            except Exception as ex:
                print(f'Silent warning! Line is \"{line}\" {ex}')

    def loadAddresses(self, dps):
        (line_no, end_line_no) = self.section_info['AD']
        for counter, line in enumerate(self.lines[line_no-2:line_no]):
            self.og_addr += f"{line}\n" 
        for counter, line in enumerate(self.lines[line_no:end_line_no+1]):
            try:
                abs_line_no = counter + line_no
                (manager, dpe_name, type_name, addr_type, addr_ref, addr_pg, addr_conn, addr_os, addr_si, addr_dir, addr_int, addr_low, addr_act, addr_st, addr_iv, addr_rep, addr_dt, addr_drv) = line.split('\t')
                if addr_drv != '"OPCUA"':
                    print (f'Skipping address type {addr_drv}, only OPCUA supported now')
                    continue
                if "OPCUACANOPENSERVER" in addr_ref:
                    self.og_addr += f"{line}\n" 
                first_dot_pos = dpe_name.find('.')
                dp_name = dpe_name[:first_dot_pos]
                #if dp_name[0] == '_':
                #    continue # skip internal DPs for now
                #print(f'(L {abs_line_no} Loading value for DPE {dpe_name}, DP {dp_name}')
                matched_dps = [dp for dp in dps if dp.name == dp_name]
                if len(matched_dps) != 1:
                    logging.error(f'Cant find DP {dp_name} (matched len was {len(matched_dps)})')
                    continue
                dp = matched_dps[0]
                post_dp_name = dpe_name[first_dot_pos+1:]
                if not post_dp_name in dp.dpes:
                    #print(f'Implicitly attaching the dpe {post_dp_name}')
                    dp.dpes[post_dp_name] = DataPointElement(post_dp_name)
                dp.dpes[post_dp_name].addr_ref = addr_ref
                dp.dpes[post_dp_name].addr_dir = addr_dir
                dp.dpes[post_dp_name].address = OpcUaPeripheralAddress(line)
                #print(f'set addr {addr_ref} on dp {dp.name}, dpe {post_dp_name}')
            except Exception as ex:
                print(f'Silent warning! Line is "{line}" {ex}')


class DistributedSystem:
    def __init__(self):
        self.dps = []

    def addDataPoints(self, system_name, dps):
        # permitted only if datapoints are not already bound to some specific system
        if any(['system' in dp.whereabouts.keys() for dp in dps ]):
            raise Exception("Can't add because at least one DP is bound to a system already")
        for dp in dps:
            dp.whereabouts['system'] = system_name
        self.dps.extend(dps)
