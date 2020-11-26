@echo off
if "%1"=="" (
  echo Usage: Test-BizTalkDatabaseConnectivity.cmd ^<databaseServer^>
  goto :EOF
)

echo Testing MS SQL connectivity:
powershell -Command Test-NetConnection %1 -Port 1433

echo Testing MS DTC connectivity:
echo.
rpcping /s %1 /O 906b0ce0-c70b-1067-b317-00dd010662da

echo.
