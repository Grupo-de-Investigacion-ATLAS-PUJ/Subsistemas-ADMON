from hashlib import new
from http import server
import os
import sys
import pdb
import argparse
import pickle
import platform
from Shelter import DpAttrMode
from madafaka import Madafaka
from lxml import etree
from enum import IntEnum
import server_fixture
from colorama import Fore, Style
from prettytable import PrettyTable, SINGLE_BORDER
import re
from opcua_dpl_validator import OpcUaDplValidator
import XPathFinder
from datetime import datetime
import lxml

ConfigNS = 'http://cern.ch/quasar/Configuration'
NSMAP = {None : ConfigNS}
XPATH_NAMESPACES = {'c' : ConfigNS}

class Validator():
    def __init__(self, config_file, madafaka, validate_server_on_vcan, output_dir=None):
        self.config_file = config_file
        self.madafaka = madafaka
        self.validate_server_on_vcan = validate_server_on_vcan
        self.output_dir = output_dir

    def validate_subscription_exists_and_is_active(self, subscription_name):
        print(f'{Fore.RED}Subscription existence test not yet there!{Style.RESET_ALL}')
        # TODO

    def validate_variable_can_be_subscribed_to(self, string_address):
        print(f'{Fore.RED}Subscriptable tests not done yet{Style.RESET_ALL}')

    def new_issue(self, dpe, opcua_address, problem_desc):
        self.issues_table.add_row([f'{dpe}', opcua_address, problem_desc])

    def run(self):
        server_fixture.run_and_dump(['/opt/CanOpenOpcUa/bin/CanOpenOpcUa', self.config_file] + (['--map_to_vcan', '--force_dont_reconfigure'] if self.validate_server_on_vcan else []))
        # at this stage we expect to have the dump.xml
        # now have to go through all fwElmb DPs and see if their PA is correct.
        issues_table = PrettyTable()
        issues_table.field_names = ['DPE', 'PA', 'Issue']
        for field in issues_table.field_names:
            issues_table.align[field] = 'l'
        self.issues_table = issues_table

        ns_tree = etree.parse('dump.xml')
        nsmap={'ns':'http://opcfoundation.org/UA/2011/03/UANodeSet.xsd'}
        OpcUaDplValidator().validate(self.madafaka, 'dump.xml', self.new_issue, 'OPCUACANOPENSERVER')
        issues_table.set_style(SINGLE_BORDER)
        print(issues_table)
        if self.output_dir is not None:
            outputFile = self.output_dir + '/validation_results.html' 
        else:
            outputFile = 'validation_results.html'
        with open(outputFile, 'w') as issues_html_out:
            issues_html_out.write(issues_table.get_html_string(attributes={"border" : "1"}))
        print(f'Validation finished -- X DPEs taken into account')

class JcopNameChunks(IntEnum):
    CANBUS = 1
    ELMB = 2
    AI = 4

def get_jcop_name_chunk(dp_name, chunks):
    chunks_split = dp_name.split('/')
    # pdb.set_trace()
    if isinstance(chunks, int):
        return chunks_split[chunks]
    else:
        raise NotImplemented

added_models = set()

def add_model(node_e, model, elmb_model_list):
    entity = etree.Entity(model)
    entity.tail = '\n      '
    node_e.append(entity)
    if model != 'STDELMB_FOUNDATIONS':
        added_models.add(model)
    elmb_model_list.append(model)

def get_path_of_model(model, standard_models_path):
    if model.startswith('STDELMB'):
        return f'{standard_models_path}/CANopen_def_{model}.xmle'
    else:
        return f'CANopen_def_{model}.xmle'

def add_ais_from_dps(madafaka, canbus_name, elmb_name, elmb_dp, new_node_e):
    for ai_dp in sorted(madafaka.query_dps(lambda dp: dp.dpt_as_str == 'FwElmbAi' and dp.name.startswith(elmb_dp.name+'/')), key=lambda dp: dp.name):
        print(ai_dp)
        channels = ai_dp.dpes['channel'].orig_value.replace('"', '').replace(' ', '').split(',')
        if not ai_dp.dpes['type'].orig_value.replace('"', '') == "Raw ADC Value":
            try:
                declared_function = ai_dp.dpes['function'].orig_value.replace('"', '').split('=')[1]
            except Exception as err:
                pdb.set_trace()
        else:
            channel = ai_dp.dpes['channel'].orig_value.replace('"', '')
            declared_function = f' $_.TPDO3.ch{channel}.value'
        # let's try to match the formula.
        
        value_formula = declared_function
        if not ai_dp.dpes['type'].orig_value.replace('"', '') == "Raw ADC Value":
            for ch in channels:
                repl_regex = re.compile(rf'({canbus_name}.{elmb_name}.ai_{ch})([^\d])')
                repl = f'$_.TPDO3.ch{ch}.value' + '\\2'
                value_formula = repl_regex.sub(repl, value_formula)
                # pdb.set_trace()
        status_formula = ''

        # TODO: watch out on what happens when we're dealing with formulas with multiple channels
        # channel = ai_dp.dpes['channel'].orig_value.
        #status_formula = f'$_.TPDO3.ch{channel}.adcFlag<128'

        status_formula = ''
        status_formulas = [f'$_.TPDO3.ch{ch}.adcFlag<128' for ch in channels] # per channel, that is.
        status_formula = ' && '.join(status_formulas)

        print(channels)
        print(status_formula)

        cv_e = etree.Element('CalculatedVariable',
            name=get_jcop_name_chunk(ai_dp.name, JcopNameChunks.AI),
            value=value_formula
            )
        cv_e.attrib['status'] = status_formula
        cv_e.tail = '\n      '
        new_node_e.append(cv_e)

def import_formulas(canbus_name, elmb_name, destination_e, older_config_file, import_formula_pattern):
    destination_xpath = XPathFinder.get_xpath_by_name(destination_e.getroottree(), destination_e, 'c:')
    print(f'Searching for calculated variables in the older config file ... (XPath is {destination_xpath})')
    older_cvs = older_config_file.xpath(destination_xpath + '/c:CalculatedVariable', namespaces = XPATH_NAMESPACES)
    for older_cv in older_cvs:
        name = older_cv.attrib['name']
        # do we have this formula in the generated content?
        new_cv_xpaths = destination_e.xpath(f"CalculatedVariable[@name='{name}']", namespaces = XPATH_NAMESPACES)
        if len(new_cv_xpaths) == 0:
            # okay, did we just identify a missing CV that is in the older config but not in the newer config?
            auto_import = any([pattern in name for pattern in import_formula_pattern])
            if auto_import:
                print(f'{Fore.BLUE}Auto-importing {name} as it matches given patterns{Style.RESET_ALL}')
                destination_e.append(older_cv) # not sure if that is entirely safe as we the context is two differing documents.
            else:
                print(f"I'm so lost. Formula named {name} is in the older config file but seems missing in the freshly generated one. What do I do?")
                pdb.set_trace()

def import_models(destination_e, older_config_file, import_models_pattern, models_list):
    if import_models_pattern is None:
        return
    destination_xpath = XPathFinder.get_xpath_by_name(destination_e.getroottree(), destination_e, 'c:')
    try:
        older_node = older_config_file.xpath(destination_xpath, namespaces = XPATH_NAMESPACES)[0]
    except:
        print(f'{Fore.RED}Cant scan models from the older file -- ELMB didnt exist?{Style.RESET_ALL}')
        return
    all_entity_refs = [child for child in older_node.getchildren() if isinstance(child, lxml.etree._Entity)]
    selected_entity_refs = [ref for ref in all_entity_refs if any(x in ref.name for x in import_models_pattern)]
    for entity_ref in selected_entity_refs:
        print(f'{Fore.BLUE}Auto-importing {entity_ref} as it matches given pattern{Style.RESET_ALL}')
        destination_e.append(entity_ref)
        models_list.append(entity_ref.name)

def deduce_DI_model(madafaka, elmb_dp):
    di_dps = madafaka.query_dps(lambda dp: dp.dpt_as_str == 'FwElmbDi'
        and dp.name.startswith(elmb_dp.name + '/'))
    if any(['DI/di_C' in di_dp.name for di_dp in di_dps]):
        return 'STDELMB_DI_TPDO1_CPR' # only with newer firmware
    else:
        return 'STDELMB_DI_TPDO1_CPR_PORTAF' # go with the oldie-goldie, works everywhere

def main():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('--pickle_in', required=True)
    parser.add_argument('--validate', action='store_true', help='Runs the CANopen OPCUA server with the generated file, and validates addresses')
    parser.add_argument('--map_to_vcan', action='store_true', help='Maps CAN ports to vcan to permit testing w/o CAN interface')
    parser.add_argument('--standard_models_path', help='Path to the dir in which std models are', default='/opt/CanOpenOpcUa/example_config')
    parser.add_argument('--custom_models_path', help='Search path for non-standard models')
    parser.add_argument('--older_config_file', default=None, help='Previous CANopen NG config file to import formulas from')
    parser.add_argument('--auto_import_formula_pattern', nargs='*', help='Pattern for which older_config_file formulas are to be auto imported')
    parser.add_argument('--auto_import_models_pattern', nargs='*', help='Pattern for which older_config_file models are to be auto imported')
    parser.add_argument('--output')
    parser.add_argument('--project_name')
    parser.add_argument('--validate_server_on_vcan', action='store_true')

    args = parser.parse_args()

    older_config_file = args.older_config_file
    if older_config_file is not None:
        parser = etree.XMLParser(resolve_entities=False)
        older_config_file = etree.parse(older_config_file, parser)

    elmb_table = PrettyTable()
    elmb_table.field_names = ['ELMB', 'Standard models', 'Custom models']
    for field in elmb_table.field_names:
        elmb_table.align[field] = 'l'

    madafaka = Madafaka(args.pickle_in)

    attr_qname = etree.QName("http://www.w3.org/2001/XMLSchema-instance", "schemaLocation")
    root = etree.Element('configuration', {attr_qname: 'http://cern.ch/quasar/Configuration /opt/CanOpenOpcUa/Configuration/Configuration.xsd'}, nsmap = NSMAP)

    root.append(etree.Comment(f'Generated at {datetime.now()} on machine {platform.node()} by user {os.getlogin()} using {sys.argv[0]}, PiotrsShelter based tool'))
    root.append(etree.Comment(f'Note: arguments were (double dash escaped to double _): {" ".join(sys.argv[1:]).replace("--", "__")}'))

    root.append(etree.Element('GlobalSettings')) # actually these could be copied from the older config file, if given TODO
    root.append(etree.Element('Warnings')) # these too could be copied from the older config file, if given TODO

    canbus_dps = madafaka.query_dps(lambda dp: dp.dpt_as_str == 'FwElmbCANbus')

    print('Found buses: ', ' '.join([bus.name for bus in canbus_dps]))

    for canbus_dp in sorted(canbus_dps, key=lambda dp: dp.name):
        # pdb.set_trace()
        canbus_name = get_jcop_name_chunk(canbus_dp.name, JcopNameChunks.CANBUS)

        bus_settings = str(int(int(canbus_dp.dpes['busSpeed'].orig_value) / 1000)) + 'k'
        port = canbus_dp.dpes['interfacePort'].orig_value.replace('"', '')

        if args.map_to_vcan:
            bus_settings = 'DontConfigure'
            port = 'vcan'+port # make it VCAN -- TODO issue with CanModule
        else:
            port = 'can' + port

        bus_e = etree.Element('Bus',
            name = canbus_name,
            syncIntervalMs = canbus_dp.dpes['syncInterval'].orig_value,
            nodeGuardIntervalMs = canbus_dp.dpes['nodeGuardInterval'].orig_value,
            port = port,
            provider = 'sock',
            settings = bus_settings
            )

        if bus_e.attrib['syncIntervalMs'] == '0':
            bus_e.attrib['syncLockOut'] = 'true'

        root.append(bus_e)


        elmb_dps = madafaka.query_dps(lambda dp: dp.dpt_as_str == 'FwElmbNode' and canbus_dp.name in dp.name)
        for elmb_dp in sorted(elmb_dps, key=lambda dp: (dp.dpes['id'].orig_value.replace('"', ''))): # TODO sort it by id on the bus
            print(f'ELMB for tha canbus is {elmb_dp.name}')
            # pdb.set_trace()

            this_elmb_models = []
            # which models ?
            has_tpdo3_analog_inputs = len(madafaka.query_dps(lambda dp: dp.dpt_as_str == 'FwElmbAi' and dp.name.startswith(elmb_dp.name + '/')))>0
            has_sdo_analog_inputs = len(madafaka.query_dps(lambda dp: dp.dpt_as_str == 'FwElmbAiSDO' and dp.name.startswith(elmb_dp.name + '/')))>0
            has_analog_outputs = len(madafaka.query_dps(lambda dp: dp.dpt_as_str == 'FwElmbAo' and dp.name.startswith(elmb_dp.name + '/')))>0
            has_digital_inputs = len(madafaka.query_dps(lambda dp: dp.dpt_as_str == 'FwElmbDi' and dp.name.startswith(elmb_dp.name + '/')))>0
            has_digital_outputs = len(madafaka.query_dps(lambda dp: dp.dpt_as_str == 'FwElmbDo' and dp.name.startswith(elmb_dp.name + '/')))>0

            elmb_name = get_jcop_name_chunk(elmb_dp.name, JcopNameChunks.ELMB)
            new_node_e = etree.Element('Node',
                name = elmb_name,
                id = elmb_dp.dpes['id'].orig_value.replace('"', ''),
                requestedState = 'OPERATIONAL', # that is to be discussed
                stateInfoSource = 'NodeGuard' # this is to be made conditional
                )
            new_node_e.text = '\n      '

            add_model(new_node_e, 'STDELMB_FOUNDATIONS', this_elmb_models)
            if has_digital_inputs:
                add_model(new_node_e, deduce_DI_model(madafaka, elmb_dp), this_elmb_models)
            if has_tpdo3_analog_inputs:
                add_model(new_node_e, 'STDELMB_AI_TPDO3', this_elmb_models)
            if has_sdo_analog_inputs:
                add_model(new_node_e, 'STDELMB_AI_SDO', this_elmb_models)
            if has_digital_outputs:
                add_model(new_node_e, 'STDELMB_DO_RPDO', this_elmb_models)
            if has_analog_outputs:
                add_model(new_node_e, 'STDELMB_AO', this_elmb_models)

            elmb_type = elmb_dp.dpes['type'].orig_value.replace('"', '')
            if elmb_type != 'ELMB':
                print('Detected ELMB with unusual type!')
                add_model(new_node_e, elmb_dp.dpes['type'].orig_value.replace('"', ''), this_elmb_models)

            add_ais_from_dps(madafaka, canbus_name, elmb_name, elmb_dp, new_node_e)



            bus_e.append(new_node_e)

            if older_config_file is not None:
                import_formulas(canbus_name, elmb_name, new_node_e, older_config_file, args.auto_import_formula_pattern)
                import_models(new_node_e, older_config_file, args.auto_import_models_pattern, this_elmb_models)

            elmb_table.add_row([elmb_dp.name,
                ', '.join([model for model in this_elmb_models if model.startswith('STD')]),
                ', '.join([model for model in this_elmb_models if not model.startswith('STD')])])



    if args.output and args.project_name:
        config_file_path = args.output + f'/CanOpenOpcUa_{args.project_name}.xml'
    else:
        config_file_path = '/ng_config.xml'
    converted_conf_fn = config_file_path
    

    #models = ['STDELMB_FOUNDATIONS', 'STDELMB_DI_TPDO1_C', 'STDELMB_AI_TPDO3', 'STDELMB_DO_RPDO']

    print ('added models are:', added_models)

    added_models_sorted = ['STDELMB_FOUNDATIONS'] + sorted(added_models)

    dt = "<!DOCTYPE configuration [\n" + \
         '\n'.join(f'  <!ENTITY {model} SYSTEM "{get_path_of_model(model, args.standard_models_path)}">' for model in added_models_sorted) + \
         "\n]>\n"

    with open(converted_conf_fn, 'wb') as fo:
        fo.write(etree.tostring(root, doctype=dt, pretty_print=True, xml_declaration=True))

    elmb_table.set_style(SINGLE_BORDER)
    print(elmb_table)

    sys.stdout.flush() # might be necessary for spawned processes for the validation step

    if args.validate:
        Validator(config_file_path, madafaka, args.validate_server_on_vcan, args.output).run()



if __name__ == '__main__':
    main()
