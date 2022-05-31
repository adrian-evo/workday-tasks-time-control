# mainly to execute trayicon as detached process

import subprocess
import json
from os.path import exists
import os, sys

def set_locale_from_vault_file():
    with open('devdata/env.json') as f:
        data = json.load(f)
    vault = data['JSON_FILE']
    assert exists(vault)

    os.environ['LANG'] = data['LOCALE']    
    return vault

if __name__ == '__main__':
    vault = set_locale_from_vault_file()
    if sys.platform.startswith('darwin'):
        subprocess.Popen(["python", "trayicon.py", vault], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    else:
        subprocess.Popen(["python", "trayicon.py", vault], creationflags=subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_BREAKAWAY_FROM_JOB)
