# mainly to execute trayicon as detached process

import subprocess
import json
from os.path import exists
import os, sys

def set_locale_from_vault_file():
    path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'devdata/env.json')
    with open(path) as f:
        data = json.load(f)
    vault = data['VAULT_FILE']
    assert exists(vault)

    os.environ['LANG'] = data['LOCALE']    
    path = os.path.join(os.path.dirname(os.path.dirname(__file__)), vault)
    return path

if __name__ == '__main__':
    vault = set_locale_from_vault_file()
    path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'src/trayicon.py')
    if sys.platform.startswith('darwin'):
        subprocess.Popen(["python", path, vault], start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
    else:
        subprocess.Popen(["python", path, vault], creationflags=subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_BREAKAWAY_FROM_JOB)
