Set WshShell = CreateObject("WScript.Shell")

' Run startup.bat silently
WshShell.Run """C:\Users\manra\admin_startup.bat""", 0, False