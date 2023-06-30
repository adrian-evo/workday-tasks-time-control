# Enable Overtime hidden menu item, that when enabled will automatically execute overtime_custom_action() implemented below once Overtime starts

overtime_menu_item_visible = False

def overtime_custom_action(self):
    import ctypes
    mb_topmost_flag = 0x00040000
    ctypes.windll.user32.MessageBoxW(0, "You overtime work just started! \n Take a break or do the Check Out!", "Overtime", 0 | 16 | mb_topmost_flag)

if __name__ == '__main__':
    overtime_custom_action()