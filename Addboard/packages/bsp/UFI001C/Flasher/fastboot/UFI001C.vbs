set wshshell=Wscript.CreateObject("WScript.Shell")
wshshell.Run "adb shell"
Wscript.Sleep 1000
wshshell.SendKeys "export TERM=linux"
wshShell.SendKeys "{ENTER}"
Wscript.Sleep 1000