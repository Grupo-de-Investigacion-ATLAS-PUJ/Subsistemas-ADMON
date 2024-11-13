import os
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)
import re
import sys
import xml.etree.ElementTree as ET
import logging
import argparse
import subprocess
from Shelter_fcc.create_html import print_pretty_results
from Shelter_fcc.create_html import db_manager
from Shelter_fcc.fcc import cross_check
from Shelter import AsciiLoader
from create_canopen_ng_opcua_config import Validator
import multiprocessing
from madafaka import Madafaka
import gitcom
import logging.config
import shutil
import time


class troublemaker():

    def __init__(self) -> None:
        self.fcc = cross_check()
        self.output = print_pretty_results()
        self.store = db_manager()
        self.subsystems = {}
        self.picked_sys = {}
        self.custom = bool()
        self.logger = logging.getLogger('CCT')
        self.logger.setLevel(logging.DEBUG)
        self.read_project_list()

    def read_project_list(self):
        tree = ET.parse('project_overview.xml')
        root = tree.getroot()
        if root.get("name") == "ATLAS":
            for child in root:
                rm_pj_name = [x for x in re.split(r"(ATL[A-Z]{3})", child.get("name")) if x]
                subsys_shorting = re.sub(r"ATL", "", rm_pj_name[0])
                if not subsys_shorting in self.subsystems.keys():
                    self.subsystems[subsys_shorting] = {}
                self.subsystems[subsys_shorting][child.get("name")] = {}
                if child.get("customtypes") == "False":
                    self.subsystems[subsys_shorting][child.get("name")]["custom"] = False
                elif child.get("customtypes") == "True":
                    self.subsystems[subsys_shorting][child.get("name")]["custom"] = True

    def list_picked_subsys(self, pj, atl_project=None):

        for system in self.subsystems:
            for subsys in self.subsystems[system]:
                if subsys == pj:
                    atl_project = pj
                    if self.subsystems[system][subsys]["custom"]:
                        self.custom = True
                    else:
                        self.custom = False

        if atl_project is None:
            self.logger.error("Project argument is not valid")
            sys.exit()
        else:
            rm_pj_name = [x for x in re.split(r"(ATL[A-Z]{3})", atl_project) if x]
            subsys_shorting = re.sub(r"ATL", "", rm_pj_name[0])
            self.picked_sys[subsys_shorting] = {}
            self.picked_sys[subsys_shorting][atl_project] = {}
            self.picked_sys[subsys_shorting][atl_project]["custom"] = int(self.custom)
            return atl_project

    def files_exists(self, sys, pj):
        cwd = os.getcwd()
        path = cwd + f"/ATLAS_DCS_REPO_CLONE/ATLAS_DCS_{sys}/{pj}"
        if not os.path.exists(path):
            self.logger.error(f"Path to project {pj} does not exists")
            return None, None

        dp_list = path + f"/dplist/{pj}_full.dpl"
        opc_config_old = path + "/config/OPCUACANOpenServer.xml"

        if not os.path.isfile(dp_list):
            self.logger.error(f"{pj}_full.dpl could not be found within cloned repository!!")
            dp_list = None
        if not os.path.isfile(opc_config_old):
            self.logger.error(f"OPCUACANOpenServer.xml for {pj} could not be found within cloned repository!!")
            opc_config_old = None
        elif self.custom:
            opc_config_old = None
        return dp_list, opc_config_old
    
    def search_for_costum_config(self, sys, pj):
        cwd = os.getcwd()
        path = cwd + f"/ATLAS_DCS_REPO_CLONE/ATLAS_DCS_{sys}/{pj}"
        if not os.path.exists(path):
            self.logger.error(f"Path to project {pj} does not exists")
            return None

        ng_config = path + f"/config/CanOpenOpcUa_{pj}.xml"

        if not os.path.isfile(ng_config):
            self.logger.error(f"NG-config for custom project could not be found within cloned repository!!")
            ng_config = False
        return ng_config
        
    def extrawurst(self, sys, pj):
        cwd = os.getcwd()
        path = cwd + f"/ATLAS_DCS_REPO_CLONE/ATLAS_DCS_{sys}"
        opc_config_old_hvpp4 = path + "/ATLPIXLV/config/OPCUACANOpenServer.xml"
        opc_config_old_sr1ilock = path + "/ATLPIXSR1ELMB/config/OPCUACANOpenServer.xml"
        opc_config_old_ATLLARCLVTEMP_EMF = path + "/ATLLARCLVTEMP_EMF/config/OPCUACANOpenServer.xml"
        dp_list = path + f"/{pj}/dplist/{pj}_full.dpl"
        dp_list_ATLLARCLVTEMP_EMF = path + f"/{pj}/dplist/ATLLARCLVTEMP_EMF2021_full.dpl"

        if pj in ["ATLPIXHVPP4",  "ATLPIXSR1ILOCK"]:
            if not os.path.isfile(dp_list):
                self.logger.error(f"{pj}_full.dpl could not be found within cloned repository!!")
                dp_list = None
        else:
            if not os.path.isfile(dp_list_ATLLARCLVTEMP_EMF):
                self.logger.error(f"{pj}_full.dpl could not be found within cloned repository!!")
                dp_list_ATLLARCLVTEMP_EMF = None

        if pj == "ATLLARCLVTEMP_EMF":
            if not os.path.isfile(opc_config_old_ATLLARCLVTEMP_EMF):
                self.logger.error(f"OPCUACANOpenServer.xml for {pj} could not be found within cloned repository!!")
                return dp_list, None
            else:
                return dp_list_ATLLARCLVTEMP_EMF, opc_config_old_ATLLARCLVTEMP_EMF

        if pj == "ATLPIXHVPP4":
            if not os.path.isfile(opc_config_old_hvpp4):
                self.logger.error(f"OPCUACANOpenServer.xml for {pj} could not be found within cloned repository!!")
                return dp_list, None
            else:
                return dp_list, opc_config_old_hvpp4
        elif pj == "ATLPIXSR1ILOCK":
            if not os.path.isfile(opc_config_old_sr1ilock):
                self.logger.error(f"OPCUACANOpenServer.xml for {pj} could not be found within cloned repository!!")
                return dp_list, None
            else:
                return dp_list, opc_config_old_sr1ilock

    def check_repos(self):
        self.logger.info("Take a look if all files for Shelter and FCC are available")
        for subsys in self.picked_sys:
            for project in self.picked_sys[subsys]:
                if project in ["ATLPIXHVPP4",  "ATLPIXSR1ILOCK", "ATLLARCLVTEMP_EMF"]:
                    dp_file, opc_file = self.extrawurst(subsys, project)
                else:
                    dp_file, opc_file = self.files_exists(subsys, project)
                self.picked_sys[subsys][project]["dp_file"] = dp_file
                self.picked_sys[subsys][project]["opc_file"] = opc_file

    def clone_data(self, pull_request):
        path = os.getcwd() + "/ATLAS_DCS_REPO_CLONE" 
        if not os.path.exists(path):
            try:
                self.logger.info("Creating main directory for cloning ATLAS_DCS repos into")
                os.mkdir(path)
            except Exception as err:
                self.logger.error(err)
                return False
        
        for sys in self.picked_sys:
            path = os.getcwd() + f"/ATLAS_DCS_REPO_CLONE/ATLAS_DCS_{sys}"
            if not os.path.exists(path):
                try:
                    self.logger.info(f"Creating directory for ATLAS_DCS_{sys} repo")
                    os.mkdir(path)
                except Exception as err:
                    self.logger.warning(err)
            try:
                gitcom.clone(path, f"https://:@gitlab.cern.ch:8443/atlas-dcs-subsystems/atlas_dcs_{sys.lower()}.git")
            except ImportError as err:
                self.logger.warning(f"{err}\n")

            if pull_request:
                self.logger.warning(f"Pulling data for {sys}")
                try:
                    gitcom.pull(path)
                except Exception as err:
                    self.logger.error(err)

        self.check_repos()
        self.logger.info("Cloning and checking repositories is finished - please check previous log output for errors\n")
    
    def push_data(self):
        print("Do you want to push the new data to the ng-migration-data repository? - [y/N]")
        if input() is 'y':
            print("Please enter commit msg now:")
            commit = input()
            print(f"Commit msg is: {commit}")
            print("Pushing to remote repo with this commit?")
            if input() is 'y':
                try:
                    pushed = int(time.time())
                    gitcom.push('/ng-migration-data', commit)
                    return True
                except Exception as err:
                    print(err)
                    return False
            else:
                return False
        else:
            return False

    def make_the_pickle(self, system, subsys, pickle_file, subfolder, og_address_file, rebuild_addrDPL):
        if self.picked_sys[system][subsys]['dp_file'] is not None:
            if os.path.isfile(og_address_file) and rebuild_addrDPL is False:
                cmd = f"python3 make_a_pickle.py --input {self.picked_sys[system][subsys]['dp_file']} --output {pickle_file}"
            elif not os.path.isfile(og_address_file) or rebuild_addrDPL is True:
                cmd = f"python3 make_a_pickle.py --input {self.picked_sys[system][subsys]['dp_file']} --output {pickle_file} --CANOPEN_addr_dpl {og_address_file}"
            try:
                result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
                if result.stdout:
                    with open(subfolder + "/migration_log/make_a_pickle_log.log", 'wb') as f:
                        f.write(result.stdout)
                if result.stderr:
                    with open(subfolder + "/migration_log/make_a_pickle_err_log.log", 'wb') as f:
                        f.write(result.stderr)
                self.picked_sys[system][subsys]["create_pickle"] = pickle_file
            except Exception as err:
                print(f"{subsys}: {err}")
                self.picked_sys[system][subsys]["create_pickle"] = False
        else:
            self.logger.warning("No _full.dpl file available")
            self.picked_sys[system][subsys]["create_pickle"] = False
    
    def generate_NGconfig(self, pickle_file, subfolder, system, subsys):
        cmd = f"python3 create_canopen_ng_opcua_config.py --pickle_in {pickle_file} --output {subfolder}/config --project_name {subsys}"
        try:
            result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
            if result.stdout:
                with open(subfolder + "/migration_log/create_canopen_ng_opcua_config_log.log", 'wb') as f:
                    f.write(result.stdout)
            if result.stderr:
                with open(subfolder + "/migration_log/create_canopen_ng_opcua_config_err_log.log", 'wb') as f:
                    f.write(result.stderr)
        except Exception as err:
            (f"{subsys}: {err}")
        
        if os.path.isfile(subfolder + f"/config/CanOpenOpcUa_{subsys}.xml"):
            self.picked_sys[system][subsys]["create_ng"] = subfolder + f"/config/CanOpenOpcUa_{subsys}.xml"
        else:
            self.picked_sys[system][subsys]["create_ng"] = False
    
    def validate_NG(self, config_file, pickle_file, subfolder, system , subsys):
        madafaka = Madafaka(pickle_file)
        validation_obj = Validator(config_file, madafaka, True, f"{subfolder}/config")
        if os.path.isfile(config_file):
            try:
                print("Start Process...")
                #multiprocessing.set_start_method('fork')
                process = multiprocessing.Process(target=validation_obj.run)
                # run the validation process
                process.start()
                # wait for the validation process to finish
                print('Waiting for the validation process...')
                process.join()
                #validation_obj.run()
            except Exception as e:
                self.logger.error(e)
        else:
            self.logger.error("No NG-config available for Validation")

        if os.path.isfile(subfolder + f"/config/validation_results.html"):
            self.picked_sys[system][subsys]["validation"] = subfolder + f"/config/validation_results.html"
        else:
            self.picked_sys[system][subsys]["validation"] = False

    def run_fcc(self, system, subsys, ng_file, subfolder):
        if self.picked_sys[system][subsys]['opc_file'] is not None:
            try:
                kwargs = {"ng_in": ng_file, "og_in": self.picked_sys[system][subsys]['opc_file'], "output": subfolder + "/config", "project" : subsys}
                self.fcc.start_fcc(**kwargs)
                self.picked_sys[system][subsys]["fcc"] = subfolder + f'/config/{subsys}_fcc_log.html'
                self.picked_sys[system][subsys]["comment"] = None
            except Exception as err:
                self.logger.error(f"{subsys}: FCC FAILED")
                self.logger.error(f"{subsys}: {err}")
                self.picked_sys[system][subsys]["fcc"] = False
                self.picked_sys[system][subsys]["comment"] = str(err)
        else:
            self.picked_sys[system][subsys]["fcc"] = False
            self.picked_sys[system][subsys]["comment"] = "No OG file could be found"

        if self.picked_sys[system][subsys]['opc_file']:
            shutil.copy(self.picked_sys[system][subsys]['opc_file'], subfolder + f"/config/{os.path.basename(self.picked_sys[system][subsys]['opc_file'])}")

    def copy_to_eos(self, project, data):
        for info in data:
            if info in ["fcc", "validation"] and data[info] is not False:
                if os.path.isfile(data[info]) and info == "fcc":
                    shutil.copy(data[info], f'/eos/home-d/decker/www/{os.path.basename(data[info])}')
                elif os.path.isfile(data[info]) and info == "validation":
                    shutil.copy(data[info], f'/eos/home-d/decker/www/{project}_{os.path.basename(data[info])}')
                        
    def checkANDbuild(self, path):
        for system in self.picked_sys:
            if not os.path.exists(path + f"/ATL_DCS_{system}"):
                try:
                    os.mkdir(path + f"/ATL_DCS_{system}")
                except Exception as err:
                    self.logger.error(err)

        for system in self.picked_sys:
            for project in self.picked_sys[system]:
                assert os.path.exists(path + f"/ATL_DCS_{system}") is True
                if not os.path.exists(path + f"/ATL_DCS_{system}/{project}"):
                    try:
                        os.mkdir(path + f"/ATL_DCS_{system}/{project}")
                        os.mkdir(path + f"/ATL_DCS_{system}/{project}/config")
                        os.mkdir(path + f"/ATL_DCS_{system}/{project}/migration_log")
                    except Exception as err:
                        self.logger.error(err)

    def check_custom_models(self, sys, subsys, config_file):
        cwd = os.getcwd()
        path = cwd + f"/ATLAS_DCS_REPO_CLONE/ATLAS_DCS_{sys}//config/CanOpenOpcUa_models"
        if not os.path.exists(path):
            return False
        else:
            cmd = f"sed \'s#/det/dcs/Production/#/home/decker/Shelter/ATLAS_DCS_REPO_CLONE/#g\' {config_file} > /home/decker/Shelter/ng-migration-data/ATL_DCS_{sys}/{subsys}/config/CanOpenOpcUa_{subsys}.xml"
            result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
            return True

    def ruin_it(self, repeat_fcc, build, validate, rebuild):
        cwd = os.getcwd()
        path = cwd + "/ng-migration-data"

        if not os.path.exists(path):
            try:
                self.logger.info("Creating folder \"ng-validation-data\" for cloning data into")
                os.mkdir(path)
            except Exception as err:
                self.logger.warning(err)
                sys.exit("FATAL ERROR")

        try:
            gitcom.clone(path, "https://:@gitlab.cern.ch:8443/decker/ng-migration-data.git")
        except ImportError as err:
            self.logger.warning(f"{err}\n")
        self.checkANDbuild(path)

        for system in self.picked_sys:
            for subsys in self.picked_sys[system]:
                self.logger.info(f"Subsystem: {subsys}")
                subfolder = path + f"/ATL_DCS_{system}/{subsys}"
               
                if self.custom:
                    pickle_file = subfolder + f"/migration_log/{subsys}.pickle"
                    validation_file = subfolder + f"/config/validation_results.html"
                    ng_file = self.search_for_costum_config(system, subsys)
                    # check if model folder was created and if change entity path
                    if not self.check_custom_models(system, subsys, ng_file):
                        self.logger.error("Cannot find the path to the custom models. The automation does not work. The programme is terminated!")
                        sys.exit(1)
                    if ng_file is not False:
                        ng_file = subfolder + f"/config/CanOpenOpcUa_{subsys}.xml"
                    og_address_file   = subfolder + f"/config/{subsys}_OLD_CANOPENSERVER_addresses.dpl"
                else:
                    pickle_file     = subfolder + f"/migration_log/{subsys}.pickle"
                    ng_file         = subfolder + f"/config/CanOpenOpcUa_{subsys}.xml"
                    validation_file = subfolder + f"/config/validation_results.html"
                    fcc_log_file    = subfolder + f"/config/{subsys}_fcc_log.html"
                    og_address_file   = subfolder + f"/config/{subsys}_OLD_CANOPENSERVER_addresses.dpl"

                #Create pickle-file out of project export (_full.dpl)
                if not os.path.isfile(pickle_file) or validate is True or build is True:
                    self.logger.info(f"{subsys}: Creating pickle file out of WinCC OA project export")
                    self.make_the_pickle(system, subsys, pickle_file, subfolder, og_address_file, rebuild)
                else:
                    self.logger.info(f"{subsys}: Pickle File allready exists - No reprocessing forced")
                    self.picked_sys[system][subsys]["create_pickle"] = pickle_file

                #Build NG-config for std projects
                if not os.path.isfile(ng_file) or build is True:
                    if self.custom is False:
                        self.logger.info(f"{subsys}: Creating ng-config!")
                        self.generate_NGconfig(pickle_file, subfolder, system, subsys)
                    else:
                        self.logger.info(f"{subsys}: Can't generate ng-config file for custom projects!")
                        self.picked_sys[system][subsys]["create_ng"] = ng_file
                else:
                    self.logger.info(f"{subsys}: NG-Config exists - No reprocessing forced")
                    self.picked_sys[system][subsys]["create_ng"] = ng_file

                #Run validation of the server
                if os.path.isfile(pickle_file):
                    if not os.path.isfile(validation_file) or validate is True:
                        self.logger.info(f"{subsys}: Run Validation!")
                        self.validate_NG(ng_file, pickle_file, subfolder, system, subsys)
                    else:
                        self.logger.info(f"{subsys}: Validation exists!")
                        self.picked_sys[system][subsys]["validation"] = validation_file
                else:
                    self.logger.warning(f"{subsys}: Validation not possible without pickle file of project export ")
                    self.picked_sys[system][subsys]["validation"] = False

                #Check formulas between OG and NG - only for std projects
                if self.custom is False:
                    if os.path.isfile(ng_file):
                        if not os.path.isfile(fcc_log_file) or repeat_fcc:
                            self.logger.info(f"{subsys}: Running Formular Cross Check (FCC)")
                            self.run_fcc(system, subsys, ng_file, subfolder)
                        else:
                            self.logger.info(f"{subsys}: Cross check was allready created")
                            self.picked_sys[system][subsys]["fcc"] = fcc_log_file
                            self.picked_sys[system][subsys]["comment"] = None
                    else:
                        self.picked_sys[system][subsys]["comment"] = "Missing NG-File"
                        self.picked_sys[system][subsys]["fcc"] = False
                else:
                    self.picked_sys[system][subsys]["comment"] = "FCC not available for Custom Projects"
                    self.picked_sys[system][subsys]["fcc"] = False

                #Copy data to eos
                self.picked_sys[system][subsys]["datalink"] = f"https://gitlab.cern.ch/decker/ng-migration-data/-/tree/master/ATL_DCS_{system}/{subsys}"
                self.copy_to_eos(subsys, self.picked_sys[system][subsys])
                #if ng_file is not False and not self.custom:
                        #shutil.copy(ng_file, subfolder + f"/config/CanOpenOpcUa_{subsys}.xml")
                self.logger.info(f"{subsys}: Finished!")

def main():
    parser = argparse.ArgumentParser(description='Load NG Server config and old Server config for formular cross check')
    parser.add_argument('--project', required=False)
    parser.add_argument('--build', required=False, action='store_true')
    parser.add_argument('--validate', required=False, action='store_true')
    parser.add_argument('--repeat_fcc', required=False, action='store_true')
    parser.add_argument('--rebuild_html', required=False, action='store_true')
    parser.add_argument('--pull_data', required=False, action='store_true')
    parser.add_argument("--set_migrated", required=False, action='store_true')
    parser.add_argument("--add_comment", required=False)
    parser.add_argument("--rebuild_OG_Addr_DPL", required=False, action='store_true')
    args = parser.parse_args()

    test = troublemaker()

    if args.add_comment != None and args.project == None:
        test.logger.error("Please specify project where you want to add a comment!")
    elif args.add_comment != None and args.project != None:
        project = test.list_picked_subsys(args.project)
        test.store.set_comment(project, args.add_comment)

    if args.set_migrated and args.project == None:
        test.logger.error("Please specify project which should be set to MIGRATED")
    elif args.set_migrated and args.project != None:
        project = test.list_picked_subsys(args.project)
        test.store.set_comment(project)
    
    if args.project == None and args.rebuild_html is False:
        test.logger.error("Please specify a specific Project or Subsystem via cmd line arguments")
        sys.exit()
    
    
    #test.store.create_table()
    if not (args.rebuild_html or args.set_migrated or args.add_comment):
        test.list_picked_subsys(args.project)
        test.clone_data(args.pull_data)
        test.ruin_it(args.repeat_fcc, args.build, args.validate, args.rebuild_OG_Addr_DPL)
        test.store.send_data_to_db(test.picked_sys)
        test.push_data()

    db_dict = test.store.db_to_dict()
    if os.path.isfile(os.getcwd() + "/Shelter_fcc/instructions.html"):
            shutil.copy(os.getcwd() + "/Shelter_fcc/instructions.html", f'/eos/home-d/decker/www/instructions.html')
    test.output.generate_main_page(db_dict)
    test.output.generate_nonSTD_validation_page(db_dict)
    test.logger.info("SHUT DOWN CCT")
    return 0

if __name__ == '__main__':
    main()