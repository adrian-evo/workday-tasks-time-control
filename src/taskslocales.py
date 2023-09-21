# Provides translation service to tray icon and Robot Framework tasks.robot file

import os
import gettext
from runtrayicon import set_locale_from_vault_file


class Translation:
    def __init__(self):
        set_locale_from_vault_file()
        self.locale = os.getenv('LANG', 'en')
        
    def get(self, text):
        path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'locales')
        return  gettext.translation('template', localedir=path, languages=[self.locale]).gettext(text)

# Robot Framework variable to be used as ${TRANS.get('Text')}
TRANS = Translation()

# Python variable to be used as _('Text')
_ = TRANS.get


# provides credential service based on the operating system (Credential Manager or Keychain)
import keyring


def retrieve_username(system):
    return keyring.get_password(system, 'username')

def retrieve_password(system, username):
    return keyring.get_password(system, username)


# running this file will regenerate the locales
if __name__ == '__main__':
    import subprocess
    import sys
    from pathlib import Path

    head, tail = os.path.split(sys.executable)
    msgfmt = head + '/Tools/i18n/msgfmt.py'
    head, tail = os.path.split(Path(__file__))
    path_en = os.path.join(os.path.dirname(head), 'locales/en/LC_MESSAGES/template')
    path_de = os.path.join(os.path.dirname(head), 'locales/de/LC_MESSAGES/template')
    print(path_en)
    subprocess.run(["python", msgfmt, path_en])
    subprocess.run(["python", msgfmt, path_de])
    print('done')    