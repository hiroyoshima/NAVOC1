function Setup-NAV-Objects {
    param (
        # Database Server
        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseServer,

        # $DatabaseNameDev
        [Parameter(Mandatory = $true)]
        [string]
        $DatabaseNameDev,

        # DatabaseNameLive
        [Parameter(Mandatory = $true)]
        [String]
        $DatabaseNameLive,

        # Database Username
        [Parameter(Mandatory = $true)]
        [string]
        $Username,

        # Password
        [Parameter(Mandatory = $true)]
        [String]
        $Password,

        # Project Path
        [Parameter(Mandatory = $true)]
        [string]
        $ProjectPath,

        # RunAsDate Exe File
        [Parameter(Mandatory = $true)]
        [String]
        $RunAsDateExe,

        # FinSQL Exe File
        [Parameter(Mandatory = $true)]
        [String]
        $FinSqlExe
    )
    #Check if RunAsDate file
    if (!(Test-Path $RunAsDateExe)) { Throw "$RunAsDateExe RunAsDate.exe file cannot be found" }
    
    # Check finsql.exe file
    if (!(Test-Path $FinSqlExe)) { Throw "$FinSqlExe finsql.exe file cannot be found" }

    $NAVObjectPath = "NAV2016 Objects"
    $NAVObjectSubPath = "$ProjectPath\$NAVObjectPath"
    New-Item $ProjectPath -Name $NAVObjectPath  -ItemType Directory -Force
    # New-Item -Path "$NAVObjectSubPath\Page", "$NAVObjectSubPath\Report","$NAVObjectSubPath\Table", "$NAVObjectSubPath\XMLPort", "$NAVObjectSubPath\Query", "$NAVObjectSubPath\Codeunit", "$NAVObjectSubPath\MenuSuite"  -ItemType Directory -Force
    New-Item -Path "$NAVObjectSubPath\Fob", "$NAVObjectSubPath\Text"  -ItemType Directory -Force

    $ExportSript = "`"$RunAsDateExe`" /movetime 26\06\2018 00:00:00 "
    $ExportSript += "`"$FinSqlExe`" command=exportobjects, "

    # Check if the database exist
    $SelectQ = "SELECT * FROM [dbo].[Object] WHERE [Type] NOT IN (0)"
    $Objects = Invoke-Sqlcmd -ServerInstance $DatabaseServer -Password $Password -Username $Username -Database $DatabasenameDev -Query $SelectQ -Encrypt Optional 
    foreach ($Object in $Objects) {
        $ObjectID = $Object.ID
        $ObjectName = $Object.Name -replace '[\W]', ' '
        $ObjectType = ""
        switch ($Object.Type) {
            1 #Table
            { $ObjectType = "Table" }
            3 #Report
            { $ObjectType = "Report" }
            5 #Codeunit
            { $ObjectType = "Codeunit" } 
            6 #XMLPort
            { $ObjectType = "XMLPort" }
            7 #MenuSuite
            { $ObjectType = "MenuSuite" }
            8 #Page
            { $ObjectType = "Page" }
            9 #Query
            { $ObjectType = "Query" }
            Default {}
        }

        if ($ObjectType -ne "") {
            $Filter = "Type=$ObjectType;ID=$ObjectID"
            $NAVObjectFilePath = "$NAVObjectSubPath"
            $NAVObjectFileName = "$NAVObjectSubPath\Text\$ObjectType $ObjectID $ObjectName DEV.txt"
            $NVObjectLogFilePath = "$NAVObjectSubPath\Text\$ObjectType $ObjectID $ObjectName LOG.txt"
            # if (!(Test-Path  $NAVObjectFilePath)) {
            #     New-Item -Path "$NAVObjectFilePath" -ItemType Directory -Force
            # }
            & cmd /c "$ExportSript servername=$DatabaseServer, database=$DatabaseNameDev, username=$Username, password=$Password, filter=$Filter, file=$NAVObjectFileName, ntauthentication=no, logfile=$NVObjectLogFilePath"
        }
    }

}

