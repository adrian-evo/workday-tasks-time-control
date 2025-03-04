# Provides translation service to tray icon and Robot Framework tasks.robot file

import os
import gettext
from runtrayicon import set_locale_from_vault_file


class Translation:
    def __init__(self):
        set_locale_from_vault_file()
        self.locale = os.getenv('LANG', 'en')
        self.translation = None
        
    def get(self, text):
        if self.translation is None:
            path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'locales')
            self.translation = gettext.translation('template', localedir=path, languages=[self.locale])
        return self.translation.gettext(text)

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

    path_en = os.path.join(os.path.dirname(head), 'locales/en/LC_MESSAGES/')
    path_de = os.path.join(os.path.dirname(head), 'locales/de/LC_MESSAGES/')

    # compile english locale
    # if custom translation exists, concatenate it with the template
    if os.path.exists(path_en + 'custom.po'):
        print('custom en translation exists')
        with open(path_en + 'combined.po', 'w') as outfile:
            with open(path_en + 'custom.po') as f1:
                outfile.write(f1.read())
            with open(path_en + 'template.po') as f2:
                outfile.write(f2.read())
        subprocess.run(["python", msgfmt, "-o", path_en + 'template.mo', path_en + 'combined.po'])
        # delete the combined file
        os.remove(path_en + 'combined.po')
    else:
        print('no en custom translation')
        subprocess.run(["python", msgfmt, path_en + 'template.po'])

    # compile german locale
    if os.path.exists(path_de + 'custom.po'):
        print('custom de translation exists')
        with open(path_de + 'combined.po', 'w') as outfile:
            with open(path_de + 'custom.po') as f1:
                outfile.write(f1.read())
            with open(path_de + 'template.po') as f2:
                outfile.write(f2.read())
        subprocess.run(["python", msgfmt, "-o", path_de + 'template.mo', path_de + 'combined.po'])
        # delete the combined file
        os.remove(path_de + 'combined.po')
    else:
        print('no de custom translation')
        subprocess.run(["python", msgfmt, path_de + 'template.po'])

    print('done')