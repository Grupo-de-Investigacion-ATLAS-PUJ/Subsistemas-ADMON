from jinja2 import Environment, FileSystemLoader
import pandas as pd
from prettytable import PrettyTable
import os
import sqlite3
from datetime import datetime

class db_manager:

    def __init__(self, directory=None, filename=None):
        self.file = filename
        self.dir = directory
    
        try:
            self.db_connection = sqlite3.connect('ng-migration-data/test_infos.db')
            self.cursor = self.db_connection.cursor()
            print("Connected to DB")
        except sqlite3.Error as err:
            print(err)
    
    def add_new_column(table_name, col_name, col_type):
        sql_cmd = f"""ALTER TABLE {table_name} ADD COLUMN {col_name} {col_type};"""
        try:
            self.cursor.execute(sql_cmd)
        except sqlite3.Error as err:
            print(err)
    
    def create_table(self):
        sql_cmd = """CREATE TABLE IF NOT EXISTS cct_data (
                        system string,
                        project string,
                        picklePATH string,
                        pickleTS time,
                        configPATH string,
                        configTS time,
                        validationPATH string,
                        validationTS time,
                        fccPATH string,
                        fccTS time,
                        fullDPL string,
                        ogCONFIG string,
                        repo string,
                        comment string
                        custom boolean
                    );"""
        try:
            self.cursor.execute(sql_cmd)
        except sqlite3.Error as err:
            print(err)
    
    def write_to_db(self, data, link, project):
        self.cursor.execute("select project from cct_data where project=?", (project,))
        entry = self.cursor.fetchall()
        if entry:
            db_write = (data["create_pickle"], data["create_pickle_mod_ts"], 
                        data["create_ng"], data["create_ng_mod_ts"], data["validation"], data["validation_mod_ts"], 
                        data["fcc"], data["fcc_mod_ts"], data["dp_file"], data["opc_file"], link, data["custom"], project)
            sql_cmd = """UPDATE cct_data SET picklePATH = ?, pickleTS  = ?, configPATH = ?, configTS = ?,
                         validationPATH = ?, validationTS = ?, fccPATH = ?, fccTS = ?, fullDPL = ?, ogCONFIG = ?,
                         repo = ?, custom = ?  WHERE project=?;"""
            try:
                self.cursor.execute(sql_cmd, db_write)
                self.db_connection.commit()
            except Exception as e:
                print(e)
        else:
            db_write = (data["system"], data["project"], data["create_pickle"], data["create_pickle_mod_ts"], 
                        data["create_ng"], data["create_ng_mod_ts"], data["validation"], data["validation_mod_ts"], 
                        data["fcc"], data["fcc_mod_ts"], data["dp_file"], data["opc_file"], link, data["custom"])
            sql_cmd = """INSERT INTO cct_data
                        (system, project, picklePATH, pickleTS, configPATH, configTS, validationPATH,
                         validationTS, fccPATH, fccTS, fullDPL, ogCONFIG, repo, custom) 
                        VALUES 
                        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"""
            try:
                self.cursor.execute(sql_cmd, db_write)
                self.db_connection.commit()
            except Exception as e:
                print(e)
        
    def send_data_to_db(self, data):
        for sys in data:
            for project in data[sys]:
                db_data_dict={}
                db_data_dict["system"] = sys
                db_data_dict["project"] = project
                for info in data[sys][project]:
                    try:
                        if info in ["create_pickle", "create_ng", "validation", "fcc"]:
                            ts = os.path.getmtime(data[sys][project][info])
                            ts = datetime.utcfromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
                            db_data_dict[info + "_mod_ts"] = ts
                            db_data_dict[info] = data[sys][project][info]
                        elif info in ["dp_file", "opc_file"]:
                            if data[sys][project][info] is None:
                                db_data_dict[info] = False
                            else:
                                db_data_dict[info] = data[sys][project][info]
                        elif info in ["custom"]:
                            db_data_dict[info] = data[sys][project][info]
                    except Exception as err:
                        print(err)
                        db_data_dict[info + "_mod_ts"] = False
                        db_data_dict[info] = False

                self.write_to_db(db_data_dict, data[sys][project]["datalink"], project)
    
    def db_to_dict(self, db_dict={}):
        df = pd.read_sql('SELECT * from cct_data', self.db_connection)
        for row in df.index:
            if not df["system"][row] in db_dict:
                db_dict[df["system"][row]] = {}
            db_dict[df["system"][row]][df["project"][row]] = {}
            for value in ["picklePATH", "configPATH", "repo", "fullDPL", "ogCONFIG", "comment", "custom"]:
                if df[value][row] == 0:
                    db_dict[df["system"][row]][df["project"][row]][value] = False
                else:
                    db_dict[df["system"][row]][df["project"][row]][value] = df[value][row]
            for value in ["validationPATH", "fccPATH"]:
                if df[value][row] == 0:
                    db_dict[df["system"][row]][df["project"][row]][value] = False
                else:
                    if value == "validationPATH":
                        file = f'{df["project"][row]}_{os.path.basename(df[value][row])}'
                    elif value == "fccPATH":
                        file = f'{os.path.basename(df[value][row])}'
                    if os.path.isfile(f'/eos/home-d/decker/www/{file}'):
                        db_dict[df["system"][row]][df["project"][row]][value] = file
                    else:
                        db_dict[df["system"][row]][df["project"][row]][value] = "File seems to exists on local disk but not on EOS"
        return db_dict

    def set_comment(self, project, comment="MIGRATED"):
        self.cursor.execute("select project from cct_data where project=?", (project,))
        entry = self.cursor.fetchall()
        if entry:
            db_write = (f"{comment}", project)
            sql_cmd = """UPDATE cct_data SET comment = ?  WHERE project=?;"""
            try:
                self.cursor.execute(sql_cmd, db_write)
                self.db_connection.commit()
            except Exception as e:
                print(e)
        print(f"{project} is now set to MIGRATED!")

class print_pretty_results():
    
    def __init__(self) -> None:
        pass

    def show_the_result(self, name, counter, max_count):
        issues_table = PrettyTable()
        issues_table.field_names = ['Project', 'Total count of formulars', 'Differs in constants', 'Differs in structure']
        for field in issues_table.field_names:
            issues_table.align[field] = 'l'
        if max_count != 0:
            const_err_percentage = (counter['var_err']/max_count)*100
            structure_err_percentage = (counter['str_err']/max_count)*100
        else:
            const_err_percentage = f"ERROR division by zero - {max_count}"
            structure_err_percentage = f"ERROR division by zero - {max_count}"
        issues_table.add_row([name, max_count, f"{const_err_percentage} %", f"{structure_err_percentage} %"])
        print(issues_table)

    def generate_html_output(self, result, name, counter, max_count, path, ng_dict, og_dict, log):

        file_loader = FileSystemLoader('templates')
        env = Environment(loader=file_loader)

        template = env.get_template('fcc_jinja_template.html')
        if max_count != 0:
            const_err_percentage = round(((counter['var_err']/max_count)*100),3)
            structure_err_percentage = round(((counter['str_err']/max_count)*100),3)
            const_structure_err_percentage = round(((counter['combined']/max_count)*100),3)
            correct_percentage = round(((counter['correct']/max_count)*100),3)
        else:
            const_err_percentage = f"ERROR division by zero - {max_count}"
            structure_err_percentage = f"ERROR division by zero - {max_count}"
            const_structure_err_percentage = f"ERROR division by zero - {max_count}"
            correct_percentage = f"ERROR division by zero - {max_count}"

        output = template.render(dict=result, name=name, count=max_count, val_err=const_err_percentage, 
                                str_err=structure_err_percentage, both_err=const_structure_err_percentage,
                                correct=correct_percentage, ng=ng_dict, og=og_dict, log=log)
        
        f = open(f'/eos/home-d/decker/www/{name}_fcc_log.html','w')
        f.write(output)
        f.close
        f = open(path + f'/{name}_fcc_log.html','w')
        f.write(output)
        f.close()
    
    def generate_main_page(self, data):
        file_loader = FileSystemLoader('templates')
        env = Environment(loader=file_loader)

        template = env.get_template('main_page_jinja_template.html')
        output = template.render(dict=data)
        f = open('/eos/home-d/decker/www/MainPage.html','w')
        f.write(output)
        f.close()
        f = open(os.getcwd() + "/ng-migration-data" + '/main_page.html','w')
        f.write(output)
        f.close()

    def generate_nonSTD_validation_page(self, data):
        file_loader = FileSystemLoader('templates')
        env = Environment(loader=file_loader)

        template = env.get_template('custom_validation_page_template.html')
        output = template.render(dict=data)
        f = open('/eos/home-d/decker/www/nonSTD_validation_page.html','w')
        f.write(output)
        f.close()
        f = open(os.getcwd() + "/ng-migration-data" + '/nonSTD_validation_page.html','w')
        f.write(output)
        f.close()

if __name__ == '__main__':
    test = print_pretty_results()