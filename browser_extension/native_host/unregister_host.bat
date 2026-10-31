@echo off
setlocal
echo Unregistering NetPulse Native Messaging Host...

REG DELETE "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.netpulse.downloader" /f
REG DELETE "HKCU\Software\Microsoft\Edge\NativeMessagingHosts\com.netpulse.downloader" /f
REG DELETE "HKCU\Software\Mozilla\NativeMessagingHosts\com.netpulse.downloader" /f

echo Done.
pause
