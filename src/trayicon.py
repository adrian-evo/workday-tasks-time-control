# Display an icon with text and specific color in systray, and update specific vault.json file with times
#   Grey - during the day, Yellow - 30' min before leave, Green - Should leave, Red - Left, Blue - During break.
#   Next day in the morning should be Red, means check-in not performed
# the update is based on data from custom vault.json given as argument to main

from threading import Event
import pystray
from pystray import Menu, MenuItem
from PIL import Image, ImageDraw,ImageFont
import os, sys, json
import subprocess
from datetime import datetime, timedelta
import psutil
from taskslocales import _
import overtimemenu

# icon data
icon_size = (48, 48)
font_size = 22

# platform specific variables - macOS or Windows
if sys.platform.startswith('darwin'):
    ttf_font = 'SFNS.ttf'
    run_task_command = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'run-tasks.sh')
    python_str = 'python'
else:
    ttf_font = 'arialbd.ttf'
    run_task_command = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'run-tasks.bat')
    python_str = 'python.exe'


# how often to update the tray icon, color and tooltip text. default 10 seconds
event_time_sleep = 10


# workday tray icon class
class WorkdayTrayIcon:
    instance = None

    def __init__(self, vault):
        # is break enabled or active
        self.break_enabled = False
        self.break_active = False

        # is overtime menu visible or active
        self.overtime_visible = overtimemenu.overtime_menu_item_visible
        self.overtime_active = False

        self.exit_event = None
        self.icon = None
        self.vault = vault

    def create_icon(self):
        self.exit_event = Event()

        # create image
        img = Image.new('RGBA', icon_size)
        d = ImageDraw.Draw(img)

        # add text to the image
        font_type  = ImageFont.truetype(ttf_font, font_size)
        d.text((10, 0.5), f"00\n00", font=font_type)

        # display icon image in systray 
        self.icon = pystray.Icon(_('Check In-Out time'))

        # icon menus
        self.icon.menu = Menu(
            MenuItem(_('Check In'), lambda : self.checkin_action()), 
            MenuItem(_('Check Out'), lambda : self.checkout_action()), 
            MenuItem(_('Verify'), lambda : self.verify_action()), 
            MenuItem(_('Custom'), lambda : self.custom_action()), 
            # Update the state in `break_action` and return the new state in a `checked` callable
            #MenuItem(_('Break'), self.break_action, checked=lambda _: self.break_active, default=True, enabled=lambda _: self.break_enabled), 
            MenuItem(_('Break'), self.break_action, checked=lambda _: self.break_active, enabled=lambda _: self.break_enabled), 
            MenuItem(_('Overtime'), self.overtime_action, checked=lambda _: self.overtime_active, visible=lambda _: self.overtime_visible), 
            MenuItem(_('Reset'), lambda : self.reset_action()), 
            MenuItem(_('Quit'), lambda : self.exit_action()), 
        )
        self.icon.icon = img
        self.icon.run(WorkdayTrayIcon.setup)

    @staticmethod
    def setup(icon: pystray.Icon) -> None:
        icon.visible = True
        while not WorkdayTrayIcon.instance.exit_event.is_set():
            WorkdayTrayIcon.instance.update_icon()
            WorkdayTrayIcon.instance.exit_event.wait(event_time_sleep)  # allows exiting while waiting. time.sleep would block

    def update_icon(self):
        # the update is based on data from custom vault.json given as argument to main
        with open(self.vault) as f:
            data = json.load(f)

        checkin_str = data['OUTPUT']['CHECKIN_DATE']
        timenow = datetime.now()

        # 1. If check-in is empty it means first run. Icon color - RED
        if checkin_str == '':
            timenow_str = timenow.strftime("%H:%M")
            self.icon.title = _('Welcome!') + ' ' +_('Please start with a Check-in task in the morning.')
            self.update_image(timenow_str, data['ICON_DATA']['CHECKOUT_DONE_COLOR'])
            self.break_enable(False)
            return

        # 2. If check-in is 00:00 it means check-out was performed. Icon color - RED
        if checkin_str == '00:00':
            self.icon.title = _('End of the working day')
            self.update_image(checkin_str, data['ICON_DATA']['CHECKOUT_DONE_COLOR'])
            self.break_enable(False)
            return

        # 3. Update Passed, Undertime or Overtime tooltip if check-in was performed for today. Icon color - GREY
        self.break_enable(True)
        checkin = datetime.strptime(checkin_str, '%Y-%m-%d %H:%M:%S.%f')
        checkout_calc = datetime.strptime(data['OUTPUT']['CHECKOUT_CALC_DATE'], '%Y-%m-%d %H:%M:%S.%f')

        # If break is active, then the CHECKOUT_CALC_DATE need to be incremented after the break
        if self.break_active:
            # save the start of break if not saved already
            if data['OUTPUT']['BREAK_TIME_TODAY'] == '':
                data['OUTPUT']['BREAK_TIME_TODAY'] = timenow.strftime('%Y-%m-%d %H:%M:%S.%f')
                with open(self.vault, 'w') as f:
                    json.dump(data, f, ensure_ascii=True, indent=4)

            break_time = datetime.strptime(data['OUTPUT']['BREAK_TIME_TODAY'], '%Y-%m-%d %H:%M:%S.%f')
            minutes = (timenow - break_time).total_seconds() / 60
            break_time += timedelta(minutes=minutes)
            passed_break_str = (datetime.fromordinal(1) + timedelta(minutes=minutes)).time().strftime("%H:%M")
            self.icon.title = _('Break is active for {} hours. Click to deactivate it and to continue working.').format(passed_break_str)
            self.update_image(passed_break_str, data['ICON_DATA']['BREAK_TIME_COLOR'])
            return
        else:
            # reset the break if not reset already
            if data['OUTPUT']['BREAK_TIME_TODAY'] != '':
                # increment and save CHECKOUT_CALC_DATE, with the amount of break time
                break_time = datetime.strptime(data['OUTPUT']['BREAK_TIME_TODAY'], '%Y-%m-%d %H:%M:%S.%f')
                minutes = (timenow - break_time).total_seconds() / 60
                checkout_calc += timedelta(minutes=minutes)
                data['OUTPUT']['BREAK_TIME_TODAY'] = ''
                data['OUTPUT']['CHECKOUT_CALC_DATE'] = checkout_calc.strftime('%Y-%m-%d %H:%M:%S.%f')
                with open(self.vault, 'w') as f:
                    json.dump(data, f, ensure_ascii=True, indent=4)

        checkin_time = checkin.strftime("%H:%M")
        checkout_time = checkout_calc.strftime("%H:%M")
        hover_text = _('Check In-Out time') + ': {}-{}'.format(checkin_time, checkout_time)
        timenow = datetime.now()
        passed = str(timenow - checkin).split('.',2)[0]
        if timenow < checkout_calc:
            left = str(checkout_calc - timenow).split('.',2)[0]
            hover_text = hover_text + ' ' + _('[Passed: {}, Undertime: {}]').format(passed, left)
            # 30' before end of the day - YELLOW, otherwise - GREY
            if (checkout_calc - timenow) <= timedelta(minutes=data['ICON_DATA']['CHECKOUT_WARNING_MINUTES']):
                self.update_image(checkout_time, data['ICON_DATA']['CHECKOUT_WARNING_COLOR'])
            else:
                self.update_image(checkout_time, data['ICON_DATA']['CHECKIN_DONE_COLOR'])
        # should check out - GREEN
        else:
            extra = str(timenow - checkout_calc).split('.',2)[0]
            hover_text = hover_text + ' ' + _('[Passed: {}, Overtime: {}]').format(passed, extra)
            self.update_image(checkout_time, data['ICON_DATA']['OVERTIME_STARTED_COLOR'])

        if self.overtime_active:
            self.update_image(checkout_time, overtimemenu.overtime_checked_color)

        # execute a custom action when overtime starts
        if self.overtime_active and timenow > checkout_calc:
            self.overtime_active = False
            self.icon.update_menu()
            self.overtime_custom_action()

        # update the tooltip
        self.icon.title = hover_text

    def update_image(self, text, color):
        # equal sign (=) in the color name means icon color before and text color after the equal sign
        if "=" in color:
            s = color.split('=')
            icon_color=s[0]
            font_color=s[1]
        else:
            icon_color=color
            font_color="None"

        # icon
        if icon_color == "None":
            img = Image.new('RGBA', icon_size)
        else:
            img = Image.new('RGBA', icon_size, color=icon_color)
        d = ImageDraw.Draw(img)

        # text
        font_type  = ImageFont.truetype(ttf_font, font_size)
        t = text.split(':')
        icon_text = t[0] + ':' + '\n' + t[1]
        #icon_text = text.replace(":", "\n")
        if font_color == "None":
            d.text((10, 0.5), f"{icon_text}", font=font_type)
        else:
            d.text((10, 0.5), f"{icon_text}", font=font_type, fill=font_color)
        self.icon.icon = img

    def exit_action(self):
        self.icon.visible = False
        self.exit_event.set()
        self.icon.stop()

    def checkin_action(self):
        # reset break if it is active during check in
        self.break_active = False
        self.update_icon()

        return subprocess.Popen([run_task_command, 'In'])

    def checkout_action(self):
        # reset break if it is active during check out
        self.break_active = False
        self.update_icon()

        return subprocess.Popen([run_task_command, 'Out'])

    def verify_action(self):
        return subprocess.Popen([run_task_command, 'Verify'])

    def custom_action(self):
        return subprocess.Popen([run_task_command, 'Custom'])

    def break_action(self, icon, item):
        if not self.break_enabled:
            return
        self.break_active = not item.checked
        self.update_icon()

    def break_enable(self, enable):
        if self.break_enabled != enable:
            self.break_enabled = enable
            self.icon.update_menu()

    def overtime_action(self, icon, item):
        self.overtime_active = not item.checked
        self.update_icon()

    def reset_action(self):
        import ctypes
        mb_topmost_flag = 0x40000
        ret = ctypes.windll.user32.MessageBoxExW(None, _("This action will reset to default all [OUTPUT] related data in your vault file! \n Continue?"), _("Reset Warning"), 4 | 48 | mb_topmost_flag)

        if ret == 6:
            data['OUTPUT']['CUMULATED_OVER_UNDER_TIME'] = ''
            data['OUTPUT']['CHECKIN_DATE'] = ''
            data['OUTPUT']['CHECKOUT_CALC_DATE'] = ''
            data['OUTPUT']['BREAK_TIME_TODAY'] = ''
            
            with open(self.vault, 'w') as f:
                json.dump(data, f, ensure_ascii=True, indent=4)


if __name__ == '__main__':
    assert len(sys.argv) == 2
    # vault file given as argument
    vault = sys.argv[1]

    # save own process pid
    with open(vault) as f:
        data = json.load(f)

    # check if it is running and don't run again
    for p in psutil.process_iter(["pid", "name"]):
        if p.info['name'] == python_str and p.info['pid'] == data['OUTPUT']['TRAY_ICON_PID']:
            print('Process with pid {} and name "{}" is running.'.format(p.info['pid'], p.info['name']))
            sys.exit()
        else:
            print('Workday tray icon not running. Starting.')
            break

    data['OUTPUT']['TRAY_ICON_PID'] = os.getpid()
    with open(vault, 'w') as f:
        json.dump(data, f, ensure_ascii=True, indent=4)

    # create workday tray icon instance
    WorkdayTrayIcon.overtime_custom_action = overtimemenu.overtime_custom_action
    WorkdayTrayIcon.instance = WorkdayTrayIcon(vault)
    WorkdayTrayIcon.instance.create_icon()
