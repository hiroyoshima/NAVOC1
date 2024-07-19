$VersionControl = "NAVOC1.00.02.48.01" # Version Control for Job Order Modifications

$Location = Get-Location
$ParentPath = "$Location\1 Backup"
$ServerName = "172.16.1.221" # Database Server of Development and Live
$DatabaseNameDev = "NAV2016_DEV3" #database name of Non-production
$DatabaseUsername = "sa" #Username
$DatabasePassword = "Password1." #Password

# Do not change the below declaration
$ObjectFilter = "Version List=*$VersionControl*"
$RunAsDateExe = "`"C:\Program Files\RunAsDate\RunAsDate.exe`" /movetime 26\06\2018 00:00:00"
$FinSQLExe = "`"C:\Program Files (x86)\Microsoft Dynamics NAV\90\RoleTailored Client\finsql.exe`" command=exportobjects, servername=$ServerName, username=$DatabaseUsername, password=$DatabasePassword,"


# Update the Version List from Development to Live
$SelectQuery = "SELECT * FROM [dbo].[Object] WHERE [Modified] = 1"
$result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameDev -Password $DatabasePassword -Username $DatabaseUsername -Query $SelectQuery -Encrypt Optional 
foreach ($Object in $result) {
    $VLID = $Object.ID
    $VLName = $Object.Name -replace '[\W]', ' '
    switch ($Object.Type) {
        1 #Table
        { 
            $FileNameFob = "$ParentPath\Table\Fob Table $VLID $VLName.fob"
            $FileNameTxt = "$ParentPath\Table\Text Table $VLID $VLName.txt"
            $ObjectFilter = "Type=Table;ID=$VLID"
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameFob, ntauthentication=no" #, logfile=$LogFileDev
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameTxt, ntauthentication=no" #, logfile=$LogFileDev
        }
        3 #Report

        {
            $FileNameFob = "$ParentPath\Report\Fob Report $VLID $VLName.fob"
            $FileNameTxt = "$ParentPath\Report\Text Report $VLID $VLName.txt"
            $ObjectFilter = "Type=Report;ID=$VLID"
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameFob, ntauthentication=no" #, logfile=$LogFileDev
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameTxt, ntauthentication=no" #, logfile=$LogFileDev

        }
        5 #Codeunit
        {
            $FileNameFob = "$ParentPath\Codeunit\Fob Codeunit $VLID $VLName.fob"
            $FileNameTxt = "$ParentPath\Codeunit\Text Codeunit $VLID $VLName.txt"
            $ObjectFilter = "Type=Codeunit;ID=$VLID"
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameFob, ntauthentication=no" #, logfile=$LogFileDev
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameTxt, ntauthentication=no" #, logfile=$LogFileDev

        }
        6 #XMLPort
        {
            $FileNameFob = "$ParentPath\XMLPort\Fob XMLPort $VLID $VLName.fob"
            $FileNameTxt = "$ParentPath\XMLPort\Text XMLPort $VLID $VLName.txt"
            $ObjectFilter = "Type=XMLPort;ID=$VLID"
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameFob, ntauthentication=no" #, logfile=$LogFileDev
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameTxt, ntauthentication=no" #, logfile=$LogFileDev

        }
        7 #MenuSuite
        {
            $FileNameFob = "$ParentPath\Menusuite\Fob Menusuite $VLID $VLName.fob"
            $FileNameTxt = "$ParentPath\Menusuite\Text Menusuite $VLID $VLName.txt"
            $ObjectFilter = "Type=Menusuite;ID=$VLID"
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameFob, ntauthentication=no" #, logfile=$LogFileDev
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameTxt, ntauthentication=no" #, logfile=$LogFileDev

        }
        8 #Page
        {
            $FileNameFob = "$ParentPath\Page\Fob Page $VLID $VLName.fob"
            $FileNameTxt = "$ParentPath\Page\Text Page $VLID $VLName.txt"
            $ObjectFilter = "Type=Page;ID=$VLID"
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameFob, ntauthentication=no" #, logfile=$LogFileDev
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameTxt, ntauthentication=no" #, logfile=$LogFileDev

        }
        9 #Query
        {
            $FileNameFob = "$ParentPath\Query\Fob Query $VLID $VLName.fob"
            $FileNameTxt = "$ParentPath\Query\Text Query $VLID $VLName.txt"
            $ObjectFilter = "Type=Query;ID=$VLID"
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameFob, ntauthentication=no" #, logfile=$LogFileDev
            & cmd /c "$RunAsDateExe $FinSQLExe database=$DatabaseNameDev, filter=$ObjectFilter, file=$FileNameTxt, ntauthentication=no" #, logfile=$LogFileDev

        }
        Default {}
    }
    
}
