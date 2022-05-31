# This PowerShell script will add %userprofile%\Rcc\ path to User environment and make it available without Windows restart

# Set new path
$value = Get-ItemProperty -Path HKCU:\Environment -Name Path;
$newpath = $value.Path += ";$env:userprofile\Rcc\;"
Set-ItemProperty -Path HKCU:\Environment -Name Path -Value $newpath;

# Update the Windows path without the need to logout or restart
$HWND_BROADCAST = [IntPtr] 0xffff;
$WM_SETTINGCHANGE = 0x1a;
$result = [UIntPtr]::Zero

if (-not ("Win32.NativeMethods" -as [Type]))
{
  # import sendmessagetimeout from win32
  Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @"
      [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
      public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
"@
}
# notify all windows of environment block change
[Win32.Nativemethods]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, "Environment", 2, 5000, [ref] $result);