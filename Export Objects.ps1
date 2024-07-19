$VersionControl = "NAVOC1.00.02.48.01" # Version Control for Job Order Modifications

$Location = "D:\Development\Dynamics NAV\NAVOC1" # Working Path
$ParentPath = "$Location\$VersionControl"
$ServerName = "172.16.1.221" # Database Server of Development and Live
$DatabaseNameDev = "NAV2016_DEV3" #database name of Non-production
$DatabaseNameLive = "NAV2016" #database name of Production
$DatabaseUsername = "sa" #Username
$DatabasePassword = "Password1." #Password

# Do not change the below declaration
$ObjectFilter = "Version List=*$VersionControl*"
$LogFileDev = "`"$ParentPath\QueryExportLogTxt.txt`""
$FileDevTxt = "$ParentPath\1 DEV_$VersionControl.txt"
$FileDevFob = "$ParentPath\2 DEV_$VersionControl.Fob"
$FileLiveTxt = "$ParentPath\1 LIVE_$VersionControl.txt"
$FileLiveFob = "$ParentPath\2 LIVE_$VersionControl.Fob"
#$DeltaFile = "$ParentPath\0 DELTAFILE_$VersionControl.txt"
$RunAsDateExe = "`"D:\Program Files\RunAsDate\RunAsDate.exe`" /movetime 26\06\2018 00:00:00"
$FinSQLExe = "`"C:\Program Files (x86)\Microsoft Dynamics NAV\90\RoleTailored Client\finsql.exe`" command=exportobjects, servername=$ServerName, username=$DatabaseUsername, password=$DatabasePassword, filter=$ObjectFilter,"


#Update the Version List from Development to Live
$SelectQuery = "SELECT * FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionControl%'"
$result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameDev -Password $DatabasePassword -Username $DatabaseUsername -Query $SelectQuery #-Encrypt Optional 

# Create new file for object list
$ObjectList = "$ParentPath\Objects.txt" # Object list
if (!(Test-Path $ObjectList)) {
    New-Item $ObjectList # Creating new text file
} else {
    Clear-Content $ObjectList # Removing text value
}

foreach ($Object in $result) {
    $VLVersionList = $Object."Version List"
    $VLType = $Object.Type
    $VLID = $Object.ID
    $VLName = $Object.Name

    # Update the Version List of Object on the Live Database
    $UpdateQuery = "UPDATE Object SET [Version List] = '$VLVersionList' WHERE Type = $VLType AND ID = $VLID"
    Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameLive -Password $DatabasePassword -Username $DatabaseUsername -Query $UpdateQuery #-Encrypt Optional 

    switch ($Object.Type) {
        1 #Table
        {$NAVObjectTypeName = "Table"}
        3 #Report
        {$NAVObjectTypeName = "Report"}
        5 #Codeunit
        {$NAVObjectTypeName = "Codeunit"}
        6 #XMLPort
        {$NAVObjectTypeName = "XMLPort"}
        7 #MenuSuite
        {$NAVObjectTypeName = "MenuSuite"}
        8 #Page
        {$NAVObjectTypeName = "Page"}
        9 #Query
        {$NAVObjectTypeName = "Query"}
        Default {}
    }
    #create Text File for the Object List
    if ((Test-Path $ObjectList) -and ($Object.Type -ne 0)) {
        $NAVObjectName = "$VLType $NAVObjectTypeName $VLID $VLName $VLVersionList"
        Add-Content -Path $ObjectList -Value $NAVObjectName
    }
}


& cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, file=$FileDevTxt, ntauthentication=no, logfile=$LogFileDev"
& cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, file=$FileDevFob, ntauthentication=no, logfile=$LogFileDev"
& cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameLive, file=$FileLiveTxt, ntauthentication=no, logfile=$LogFileDev"
& cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameLive, file=$FileLiveFob, ntauthentication=no, logfile=$LogFileDev"


# if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
# Set-ExecutionPolicy unrestricted -Force
# import-module "C:\Program Files\Microsoft Dynamics NAV\90\Service\NavAdminTool.ps1"
# Import-Module "C:\Program Files (x86)\Microsoft Dynamics NAV\90\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1"

# Compare-NAVApplicationObject -OriginalPath "$FileLiveTxt" -ModifiedPath "$FileDevTxt" -DeltaPath "$DeltaFile" -Force