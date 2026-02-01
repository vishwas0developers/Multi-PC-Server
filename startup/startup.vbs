Set WshShell = CreateObject("WScript.Shell")

' Run startup.bat silently
WshShell.Run """C:\Users\manra\startup.bat""", 0, False

' Run duckdns-loop.bat silently in parallel
WshShell.Run """C:\Users\manra\duckdns-loop.bat""", 0, False

