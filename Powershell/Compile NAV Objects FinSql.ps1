$RunAsDateExe = "D:\Program Files\RunAsDate\RunAsDate.exe"
$FinSqlExe = "C:\Program Files (x86)\Microsoft Dynamics NAV\90\RoleTailored Client\finsql.exe"
$ServerName = $env:DATABASE_SERVER
$Username = $env:USERNAME
$Password = $env:PASSWORD
$Filter = "Type=Table;ID=50562"
$Database = $env:DATABASE_DEV
$ExportSript = "`"$RunAsDateExe`" /movetime 26\06\2018 00:00:00 "
$ExportSript += "`"$FinSqlExe`" command=compileobjects, "
$ExportSript += "servername=$ServerName, username=$Username, password=$Password, filter=$Filter,"
# DESKTOP-JPN0C0B
# win-1loplpr4b4m
& cmd /c "$ExportSript database=$Database, ntauthentication=no, logfile=D:\Log.txt, synchronizeschemachanges=force, navservername=development.onecommerce.com.ph, navserverinstance=dynamicsnav90, navservermanagementport=7045"