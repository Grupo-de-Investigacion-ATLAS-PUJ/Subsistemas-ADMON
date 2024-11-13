import git
import re
import os
import sys
import logging

#logger = logging.getLogger(__name__)

def push(target_folder, comment):
    cwd = os.getcwd()
    try:
        repo = git.Repo(cwd + target_folder)
        repo.git.add(all=True)
        repo.index.commit(comment)
        origin = repo.remote(name='origin')
        assert origin.exists()
        info = repo.git.push("--set-upstream", origin, repo.head.ref)
        logging.info(info)
    except Exception as err:
        logging.error(err)
        logging.error('Some error occured while pushing the code') 

def clone(target_folder, repository):
    if os.path.exists(target_folder):
        if os.path.exists(target_folder + "/.git"):
            git_log = (open(target_folder + "/.git/logs/HEAD", "r")).read()
            git_log = [x for x in re.split(r"\t", re.sub(r"clone: from ", "", git_log)) if x]
            if re.match("ssh:/.*", git_log[1]) or re.match("https:/.*", git_log[1]):
                if re.match(f"{repository}", git_log[1]):
                    logging.info(f"{repository} was allready cloned")
                    raise ImportError(f"Repository \"{repository}\" was allready cloned")
                else:
                    logging.warning(f"A different Repo was allready cloned into this directory ({target_folder})")
            else:
                logging.error(f"Could not identify the repository which was cloned into {target_folder}!")
        else:
            logging.info(f"Cloning \"{repository}\" repo. Could take some time..." )
            try:
                git.Repo.clone_from(repository, target_folder, depth=1)
            except git.GitError as err:
                logging.error("Tried cloning but following error appeared:")
                logging.error(err)
            logging.info("Cloning finished")

def pull(target_folder):
    try:
        repo = git.Repo(target_folder)
        origin = repo.remote(name='origin')
        origin.pull()
    except git.GitError as err:
        print(err)
        logging.error(err)
        logging.error("Pulling from remote repository did not work")

    