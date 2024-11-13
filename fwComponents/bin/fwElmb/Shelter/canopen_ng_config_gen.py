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


def make_the_pickle(dpl_file, pickle_file, shelter_path, log_path):
    cmd = f"python3.9 {shelter_path}/make_a_pickle.py --input {dpl_file} --output {log_path + pickle_file}"
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        if result.stdout:
            with open(log_path + "/make_a_pickle.log", 'wb') as f:
                f.write(result.stdout)
        if result.stderr:
            with open(log_path + "/make_a_pickle_err.log", 'wb') as f:
                f.write(result.stderr)
                print("Errors in creating pickle file, check error logs")
        
    except Exception as err:
        print(f"{err}")

def generate_NGconfig(pickle_file, proj_name, shelter_path, config_storage, log_path):
    cmd = f"python3.9 {shelter_path}/create_canopen_ng_opcua_config.py --pickle_in {log_path + pickle_file} --output {config_storage} --project_name {proj_name}"
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        if result.stdout:
            with open(log_path + "create_canopen_ng_opcua_config.log", 'wb') as f:
                f.write(result.stdout)
        if result.stderr:
            with open(log_path + "create_canopen_ng_opcua_config_err.log", 'wb') as f:
                f.write(result.stderr)
                print("Errors in creating NG config file, check error logs")
    except Exception as err:
        (f"{err}")
                
def main():
    parser = argparse.ArgumentParser(description='Load NG Server config and old Server config for formular cross check')
    parser.add_argument('--dplPath', metavar='\b', dest='dplPath', type=str)
    parser.add_argument('--projectName', metavar='\b', dest='projectName', type=str)
    parser.add_argument('--shelterPath', metavar='\b', dest='shelterPath', type=str)
    parser.add_argument('--configStoragePath', metavar='\b', dest='configStoragePath', type=str)
    parser.add_argument('--logStoragePath', metavar='\b', dest='logStoragePath', type=str)
    args = parser.parse_args()
    
    pickleFile = (args.projectName + ".pickle")
    
    print("Creating pickle file out of WinCC OA project export")
    make_the_pickle(args.dplPath, pickleFile, args.shelterPath, args.logStoragePath)
    print("Creating NG config file from pickle file")
    generate_NGconfig(pickleFile, args.projectName, args.shelterPath, args.configStoragePath, args.logStoragePath)

    if args.configStoragePath[-1] == "/" :
        if os.path.isfile(args.configStoragePath + "CanOpenOpcUa_" + args.projectName + ".xml"): print("CanOpenOpcUa NG config file successfully generated")
        else: print("Error creating config file, check log files in: " + args.logStoragePath)
    else:
        if os.path.isfile(args.configStoragePath + "/CanOpenOpcUa_" + args.projectName + ".xml"): print("CanOpenOpcUa NG config file successfully generated")
        else: print("Error creating config file, check log files in: " + args.logStoragePath)

if __name__ == '__main__':
    main()
