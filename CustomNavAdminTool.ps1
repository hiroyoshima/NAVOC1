Get-Content .\.env | foreach {
    $name, $value = $_.split('=')
    Set-Content env:\$name $value
}


function Export-Nav-Objects {
    param (
        # Project Path
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Database Server Name
        [Parameter(Mandatory = $true)]
        [string]
        $ServerName,

        # Database Username
        [Parameter(Mandatory = $true)]
        [string]
        $Username,

        # Database Password
        [Parameter(Mandatory = $true)]
        [string]
        $Password,

        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $VersionList,

        # Database name of development
        [Parameter(Mandatory = $true)]
        [string]
        $DatabaseNameDev,

        [Parameter(Mandatory = $false)]
        [boolean]
        $ExportDevFob,

        # Database name of Live
        [Parameter(Mandatory = $false)]
        [string]
        $DatabaseNameLive,

        # RunAsDate Exe File
        [Parameter(Mandatory = $true)]
        [String]
        $RunAsDateExe,

        # FinSQL Exe File
        [Parameter(Mandatory = $true)]
        [String]
        $FinSqlExe
    )
    #Check if Version List has corresponding result
    $SelectQuery = "SELECT COUNT(ID) AS Result FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameDev -Password $Password -Username $Username -Query $SelectQuery #-Encrypt Optional
    if ($result.Result -eq 0) { Throw "There's no Version List found using the Version $VersionList" }
    #Check if project path is valid
    if (!(Test-Path $Path)) { Throw "$Path path cannot be found." }

    # New-Item $Path -Name "Development"  -ItemType Directory -Force
    New-Item $Path -Name "Live"  -ItemType Directory -Force
    New-Item $Path -Name "Logs"  -ItemType Directory -Force

    if (!(Test-Path $RunAsDateExe)) { Throw "$RunAsDateExe RunAsDate.exe file cannot be found." } #Check if RunAsDate file
    if (!(Test-Path $FinSqlExe)) { Throw "$FinSqlExe finsql.exe file cannot be found." } # Check finsql.exe file

    #$DeltaFile = "$Path\0 DELTAFILE_$VersionList.txt"
    $ExportSript = "`"$RunAsDateExe`" /movetime 26\06\2018 00:00:00 "
    $ExportSript += "`"$FinSqlExe`" command=exportobjects, "
    $ExportSript += "servername=$ServerName, username=$Username, password=$Password, filter=Version List=*$VersionList,"

    #Export NAV Objects Command
    & cmd /c "$ExportSript database=$DatabaseNameDev, file=$Path\DEV $VersionList.txt, ntauthentication=no, logfile=$Path\Logs\DEV $VersionList.txt"
    if ($ExportDevFob) {
        # Allow Export DevFob
        & cmd /c "$ExportSript database=$DatabaseNameDev, file=$Path\DEV $VersionList.fob, ntauthentication=no" 
    }

    #Update the Version List from Development to Live
    if ($DatabaseNameLive -ne "") {
        $SelectQuery = "SELECT * FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
        $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameDev -Password $Password -Username $Username -Query $SelectQuery #-Encrypt Optional 

        # # Create new file for object list
        # $ObjectList = "$Path\Objects.txt" # Object list
        # if (!(Test-Path $ObjectList)) {
        #     New-Item $ObjectList # Creating new text file
        # } else {
        #     Clear-Content $ObjectList # Removing text value
        # }

        foreach ($Object in $result) {
            $VLVersionList = $Object."Version List"
            $VLType = $Object.Type
            $VLID = $Object.ID
            $VLName = $Object.Name

            # Update the Version List of Object on the Live Database
            $UpdateQuery = "UPDATE Object SET [Version List] = '$VLVersionList' WHERE Type = $VLType AND ID = $VLID"
            Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameLive -Password $Password -Username $Username -Query $UpdateQuery #-Encrypt Optional 

            # switch ($Object.Type) {
            #     1 #Table
            #     {$NAVObjectTypeName = "Table"}
            #     3 #Report
            #     {$NAVObjectTypeName = "Report"}
            #     5 #Codeunit
            #     {$NAVObjectTypeName = "Codeunit"}
            #     6 #XMLPort
            #     {$NAVObjectTypeName = "XMLPort"}
            #     7 #MenuSuite
            #     {$NAVObjectTypeName = "MenuSuite"}
            #     8 #Page
            #     {$NAVObjectTypeName = "Page"}
            #     9 #Query
            #     {$NAVObjectTypeName = "Query"}
            #     Default {}
            # }
            # #create Text File for the Object List
            # if ((Test-Path $ObjectList) -and ($Object.Type -ne 0)) {
            #     $NAVObjectName = "$VLType $NAVObjectTypeName $VLID $VLName $VLVersionList"
            #     Add-Content -Path $ObjectList -Value $NAVObjectName
            # }
        }
        
        & cmd /c "$ExportSript database=$DatabaseNameLive, file=$Path\Live\LIVE $VersionList.txt, ntauthentication=no, logfile=$Path\Logs\LIVE $VersionList.txt"
        & cmd /c "$ExportSript database=$DatabaseNameLive, file=$Path\Live\LIVE $VersionList.fob, ntauthentication=no"
    }
    
}

function Export-Nav-Objects-Beta {
    param (
        # Project Path
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $VersionList,

        # Staging Development or Live
        [string]
        $StagingType = "Development",
        
        [string]
        $ExportType = "Both Fob and Text"
    )
    
    if (!(Test-Path $Path)) { Throw "$Path path cannot be found." } #Check if project path is valid
    if (!(Test-Path $env:RUNASDATE)) { Throw "$env:RUNASDATE RunAsDate.exe file cannot be found." } #Check if RunAsDate file
    if (!(Test-Path $env:FINSQL)) { Throw "$env:FINSQL finsql.exe file cannot be found." } # Check finsql.exe file

    if ([string]::IsNullOrEmpty($env:DATABASE_LIVE)) { Throw "DATABASE_LIVE must have a value in .env file." }
    if ([string]::IsNullOrEmpty($env:NAVSERVERNAME_LIVE)) { Throw "NAVSERVERNAME_LIVE must have a value in .env file." }
    if ([string]::IsNullOrEmpty($env:NAVSERVERINSTANCE_LIVE)) { Throw "NAVSERVERINSTANCE_LIVE must have a value in .env file." }
    if ([string]::IsNullOrEmpty($env:NAVSERVERMANAGMENTPORT_LIVE)) { Throw "NAVSERVERMANAGMENTPORT_LIVE must have a value in .env file." }

    if ([string]::IsNullOrEmpty($env:DATABASE_DEV)) { Throw "DATABASE_DEV must have a value in .env file." }
    if ([string]::IsNullOrEmpty($env:NAVSERVERNAME_DEV)) { Throw "NAVSERVERNAME_DEV must have a value in .env file." }
    if ([string]::IsNullOrEmpty($env:NAVSERVERINSTANCE_DEV)) { Throw "NAVSERVERINSTANCE_DEV must have a value in .env file." }
    if ([string]::IsNullOrEmpty($env:NAVSERVERMANAGMENTPORT_DEV)) { Throw "NAVSERVERMANAGMENTPORT_DEV must have a value in .env file." }

    New-Item $Path -Name "Live"  -ItemType Directory -Force
    New-Item $Path -Name "Logs"  -ItemType Directory -Force

    #Check if Version List has corresponding result
    $SelectQuery = "SELECT COUNT(ID) AS Result FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
    $cmd = "`"$env:RUNASDATE`" /movetime 26\06\2018 00:00:00 `"$env:FINSQL`" command=exportobjects, "
    switch ($StagingType) {
        "Live" { 
            $result = Invoke-Sqlcmd -ServerInstance $env:DATABASE_SERVER -Database $env:DATABASE_LIVE -Username $env:USERNAME -Password $env:PASSWORD -Query $SelectQuery #-Encrypt Optional
            if ($result.Result -eq 0) { Throw "There's no Version List found using the Version $VersionList" }
            
            $cmd += "servername=$env:DATABASE_SERVER, username=$env:USERNAME, password=$env:PASSWORD, filter=Version List=*$VersionList,"
            $cmd += "database=$env:DATABASE_LIVE,ntauthentication=$env:NTAUTHENTICATION_LIVE, "

            switch ($ExportType) {
                "Text" {
                    & cmd /c "$cmd file=$Path\Live\LIVE $VersionList.txt, logfile=$Path\Live\ExportLogsText.txt"
                }
                "Fob" {
                    & cmd /c "$cmd file=$Path\Live\LIVE $VersionList.fob, logfile=$Path\Live\ExportLogsFob.txt"
                }
                Default {
                    & cmd /c "$cmd file=$Path\Live\LIVE $VersionList.txt, logfile=$Path\Live\ExportLogsText.txt"
                    & cmd /c "$cmd file=$Path\Live\LIVE $VersionList.fob, logfile=$Path\Live\ExportLogsFob.txt"
                }
            }
        }
        "Development" { 
            $SelectQuery = "SELECT * FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
            $result = Invoke-Sqlcmd -ServerInstance $env:DATABASE_SERVER -Database $env:DATABASE_DEV -Username $env:USERNAME -Password $env:PASSWORD -Query $SelectQuery #-Encrypt Optional 
            if ($result.Result -eq 0) { Throw "There's no Version List found using the Version $VersionList" }

            $cmd += "servername=$env:DATABASE_SERVER, username=$env:USERNAME, password=$env:PASSWORD, filter=Version List=*$VersionList,"
            $cmd += "database=$env:DATABASE_DEV,ntauthentication=$env:NTAUTHENTICATION_DEV, "

            foreach ($Object in $result) {
                $VLVersionList = $Object."Version List"
                $VLType = $Object.Type
                $VLID = $Object.ID
                $VLName = $Object.Name

                # Update the Version List of Object on the Live Database
                $UpdateQuery = "UPDATE Object SET [Version List] = '$VLVersionList' WHERE Type = $VLType AND ID = $VLID"
                Invoke-Sqlcmd -ServerInstance $env:DATABASE_SERVER -Database $env:DATABASE_LIVE -Password $env:PASSWORD -Username $env:USERNAME -Query $UpdateQuery #-Encrypt Optional 
            }
            switch ($ExportType) {
                "Text" {
                    & cmd /c "$cmd file=$Path\DEV $VersionList.txt, logfile=$Path\ExportLogsText.txt"
                }
                "Fob" {
                    & cmd /c "$cmd file=$Path\DEV $VersionList.fob, logfile=$Path\ExportLogsFob.txt"
                }
                Default {
                    & cmd /c "$cmd file=$Path\DEV $VersionList.txt, logfile=$Path\ExportLogsText.txt"
                    & cmd /c "$cmd file=$Path\DEV $VersionList.fob, logfile=$Path\ExportLogsFob.txt"
                }
            }
        }
        Default {
            Throw "Not included in StagingType option. Please select Live or Development only." 
        }
    }
    
}

function Create-Delta-File {
    param (
        # Project Path
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Database Server Name
        [Parameter(Mandatory = $true)]
        [string]
        $ServerName,

        # Database Username
        [Parameter(Mandatory = $true)]
        [string]
        $Username,

        # Database Password
        [Parameter(Mandatory = $true)]
        [string]
        $Password,

        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $VersionList,

        # Database name of development
        [Parameter(Mandatory = $true)]
        [string]
        $DatabaseOrig,

        # Database name of development
        [Parameter(Mandatory = $true)]
        [string]
        $DatabaseOld,

        # RunAsDate Exe File
        [Parameter(Mandatory = $true)]
        [String]
        $RunAsDateExe,

        # FinSQL Exe File
        [Parameter(Mandatory = $true)]
        [String]
        $FinSqlExe
    )
    #Check if Version List has corresponding result
    $SelectQuery = "SELECT COUNT(ID) AS Result FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseOrig -Password $Password -Username $Username -Query $SelectQuery #-Encrypt Optional
    if ($result.Result -eq 0) { Throw "There's no Version List found using the Version $VersionList" }
    if (!(Test-Path $Path)) { Throw "$Path path cannot be found." }#Check if project path is valid
    if (!(Test-Path $RunAsDateExe)) { Throw "$RunAsDateExe RunAsDate.exe file cannot be found." } #Check if RunAsDate file
    if (!(Test-Path $FinSqlExe)) { Throw "$FinSqlExe finsql.exe file cannot be found." } # Check finsql.exe file

    #$DeltaFile = "$Path\0 DELTAFILE_$VersionList.txt"
    $ExportSript = "`"$RunAsDateExe`" /movetime 26\06\2018 00:00:00 "
    $ExportSript += "`"$FinSqlExe`" command=exportobjects, "
    $ExportSript += "servername=$ServerName, username=$Username, password=$Password, filter=Version List=*$VersionList,"
    
    New-Item $Path -Name "Logs"  -ItemType Directory -Force

    $ModifiedPath = "$Path\Logs\#ModifiedObject.txt"
    $OriginalPath = "$Path\Logs\#OriginalObject.txt"

    #Export NAV Objects Command
    & cmd /c "$ExportSript database=$DatabaseOrig, file=$ModifiedPath, ntauthentication=no, logfile=$Path\Logs\DEV $VersionList.txt"

    #Update the Version List from Development to Live
    $SelectQuery = "SELECT * FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseOrig -Password $Password -Username $Username -Query $SelectQuery #-Encrypt Optional 

    foreach ($Object in $result) {
        $VLVersionList = $Object."Version List"
        $VLType = $Object.Type
        $VLID = $Object.ID

        # Update the Version List of Object on the Live Database
        $UpdateQuery = "UPDATE Object SET [Version List] = '$VLVersionList' WHERE Type = $VLType AND ID = $VLID"
        Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseOld -Password $Password -Username $Username -Query $UpdateQuery #-Encrypt Optional 
    }

    & cmd /c "$ExportSript database=$DatabaseOld, file=$OriginalPath, ntauthentication=no, logfile=$Path\Logs\LIVE $VersionList.txt"
}

function Create-Delta-File-Beta {
    param (
        # Project Path
        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Parameter help description
        [Parameter(Mandatory = $true)]
        [string]
        $VersionList

    )
    #Check if Version List has corresponding result
    $SelectQuery = "SELECT COUNT(ID) AS Result FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
    $result = Invoke-Sqlcmd -ServerInstance $env:DATABASE_SERVER -Database $env:DATABASE_LIVE -Password $env:PASSWORD -Username $env:USERNAME -Query $SelectQuery #-Encrypt Optional
    if ($result.Result -eq 0) { Throw "There's no Version List found using the Version $VersionList" }
    if (!(Test-Path $Path)) { Throw "$Path path cannot be found." }#Check if project path is valid
    if (!(Test-Path $env:RUNASDATE)) { Throw "$env:RUNASDATE RunAsDate.exe file cannot be found." } #Check if RunAsDate file
    if (!(Test-Path $env:FINSQL)) { Throw "$env:FINSQL finsql.exe file cannot be found." } # Check finsql.exe file

    #$DeltaFile = "$Path\0 DELTAFILE_$VersionList.txt"
    $cmd = "`"$env:RUNASDATE`" /movetime 26\06\2018 00:00:00 "
    $cmd += "`"$env:FINSQL`" command=exportobjects, "
    $cmd += "servername=$env:DATABASE_SERVER, username=$env:USERNAME, password=$env:PASSWORD, filter=Version List=*$VersionList,"
    
    New-Item $Path -Name "Logs"  -ItemType Directory -Force

    $ModifiedPath = "$Path\Logs\#ModifiedObject.txt"
    $OriginalPath = "$Path\Logs\#OriginalObject.txt"

    #Export NAV Objects Command
    & cmd /c "$cmd database=$env:DATABASE_LIVE, file=$ModifiedPath, ntauthentication=no, logfile=$Path\Logs\DEV $VersionList.txt"

    #Update the Version List from Development to Live
    $SelectQuery = "SELECT * FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
    $result = Invoke-Sqlcmd -ServerInstance $env:DATABASE_SERVER -Database $env:DATABASE_LIVE -Password $env:PASSWORD -Username $env:USERNAME -Query $SelectQuery #-Encrypt Optional 

    foreach ($Object in $result) {
        $VLVersionList = $Object."Version List"
        $VLType = $Object.Type
        $VLID = $Object.ID

        # Update the Version List of Object on the Live Database
        $UpdateQuery = "UPDATE Object SET [Version List] = '$VLVersionList' WHERE Type = $VLType AND ID = $VLID"
        Invoke-Sqlcmd -ServerInstance $env:DATABASE_SERVER -Database $DatabaseOld -Password $Password -Username $Username -Query $UpdateQuery #-Encrypt Optional 
    }

    & cmd /c "$cmd database=$DatabaseOld, file=$OriginalPath, ntauthentication=no, logfile=$Path\Logs\LIVE $VersionList.txt"
}

function Import-NAV-Objects {
    param (
        # File  path of object to import
        [Parameter(Mandatory = $true)]
        [string]
        $File,

        # Development or Live
        [Parameter(Mandatory = $true)]
        [string]
        $StagingType
    )
    #Check if project path is valid
    $Path = (Get-Item $File ).DirectoryName
    $File = [IO.Path]::ChangeExtension($File, [NullString]::Value)
    $File = "$File.fob"
    if (!(Test-Path $File)) { Throw "$File path cannot be found." } # Check if nav object file
    if (!(Test-Path $env:RUNASDATE)) { Throw "$env:RUNASDATE RunAsDate.exe file cannot be found." } #Check if RunAsDate file
    if (!(Test-Path $env:FINSQL)) { Throw "$env:FINSQL finsql.exe file cannot be found." } # Check finsql.exe file
    # finsql.exe command=importobjects, 
    # file=<importfile>, 
    # [servername=<server>,] 
    # [database=<database>,] 
    # [logfile=<path and filename>,] 
    # [importaction=<default|overwrite|skip|0|1|2>,] 
    # [username=<username>,] 
    # [password=<password>,] 
    # [ntauthentication=<yes|no|1|0>,] 
    # [synchronizeschemachanges=<yes|no|force>,] 
    # [navservername=<server name>,] 
    # [navserverinstance=<instance>,] 
    # [navservermanagementport=<port>,] 
    # [tenant=<tenant ID>]
    $cmd = "`"$env:RUNASDATE`" /movetime 26\06\2018 00:00:00 `"$env:FINSQL`" "
    if ($StagingType = "Live") {
        # Live Server
        if ([string]::IsNullOrEmpty($env:DATABASE_LIVE)) { Throw "DATABASE_LIVE must have a value in .env file." }
        if ([string]::IsNullOrEmpty($env:NAVSERVERNAME_LIVE)) { Throw "NAVSERVERNAME_LIVE must have a value in .env file." }
        if ([string]::IsNullOrEmpty($env:NAVSERVERINSTANCE_LIVE)) { Throw "NAVSERVERINSTANCE_LIVE must have a value in .env file." }
        if ([string]::IsNullOrEmpty($env:NAVSERVERMANAGMENTPORT_LIVE)) { Throw "NAVSERVERMANAGMENTPORT_LIVE must have a value in .env file." }

        $cmd += "command=importobjects, servername=$env:DATABASE_SERVER, username=$env:USERNAME, password=$env:PASSWORD, database=$env:DATABASE_LIVE, "
        $cmd += "ntauthentication=$env:NTAUTHENTICATION_LIVE, importaction=overwrite, navservername=$env:NAVSERVERNAME_LIVE, navserverinstance=$env:NAVSERVERINSTANCE_LIVE, navservermanagementport=$env:NAVSERVERMANAGMENTPORT_LIVE, "
    }
    else {
        # Development
        if ([string]::IsNullOrEmpty($env:DATABASE_DEV)) { Throw "DATABASE_DEV must have a value in .env file." }
        if ([string]::IsNullOrEmpty($env:NAVSERVERNAME_DEV)) { Throw "NAVSERVERNAME_DEV must have a value in .env file." }
        if ([string]::IsNullOrEmpty($env:NAVSERVERINSTANCE_DEV)) { Throw "NAVSERVERINSTANCE_DEV must have a value in .env file." }
        if ([string]::IsNullOrEmpty($env:NAVSERVERMANAGMENTPORT_DEV)) { Throw "NAVSERVERMANAGMENTPORT_DEV must have a value in .env file." }

        $cmd += "command=importobjects, servername=$env:DATABASE_SERVER, username=$env:USERNAME, password=$env:PASSWORD, database=$env:DATABASE_DEV, "
        $cmd += "ntauthentication=$env:NTAUTHENTICATION_DEV, importaction=overwrite, navservername=$env:NAVSERVERNAME_DEV, navserverinstance=$env:NAVSERVERINSTANCE_DEV, navservermanagementport=$env:NAVSERVERMANAGMENTPORT_DEV, "
    }

    $cmd += "file=$File, logfile=$Path\ImportLog.txt"
    & cmd /c $cmd
}

function Import-NAV-Object-Result {
    param (
        # Import Log File
        [Parameter(Mandatory = $true)]
        [string]
        $ImportLogPath
    )

    $ImportLog = "$ImportLogPath\ImportLog.txt"
    $NavCmdRes = "$ImportLogPath\navcommandresult.txt"
    if ((Test-Path $ImportLog)) {
        $ErrMsg = Get-Content $ImportLog
        $ErrMsg += "`n`n"
        $ErrMsg += Get-Content $NavCmdRes
        Remove-Item -Path $ImportLog
        Remove-Item -Path $NavCmdRes
        Throw $ErrMsg
    }
    else {
        Get-Content $NavCmdRes
        Remove-Item -Path $NavCmdRes
    }
    
}

function NAV-Version-Control {
    param (
        # Project Path
        [Parameter(Mandatory = $false)]
        [string]
        $NAVVersion
    )
    $Location = Get-Location
    $Path = "$Location"
    $ServerName = $env:DATABASE_SERVER
    $Username = $env:USERNAME
    $Password = $env:PASSWORD
    $DatabaseNameDev = $env:VERSION_CONTROL_DATABASE
    $RunAsDateExe = $env:RUN_AS_DATE
    $FinSqlExe = $env:FIN_SQL

    if (!(Test-Path $RunAsDateExe)) { Throw "$RunAsDateExe RunAsDate.exe file cannot be found." } #Check if RunAsDate file
    if (!(Test-Path $FinSqlExe)) { Throw "$FinSqlExe finsql.exe file cannot be found." } # Check finsql.exe file

    $ParentPath = "$Path\ONE COMMERCE"
    if (!(Test-Path "$Path\Table")) { New-Item $ParentPath -Name "Table"  -ItemType Directory -Force}
    if (!(Test-Path "$Path\Report")){ New-Item $ParentPath -Name "Report"  -ItemType Directory -Force}
    if (!(Test-Path "$Path\Codeunit")){ New-Item $ParentPath -Name "Codeunit"  -ItemType Directory -Force}
    if (!(Test-Path "$Path\Page")){ New-Item $ParentPath -Name "Page"  -ItemType Directory -Force}
    if (!(Test-Path "$Path\XMLPort")){ New-Item $ParentPath -Name "XMLPort"  -ItemType Directory -Force}
    if (!(Test-Path "$Path\MenuSuite")){ New-Item $ParentPath -Name "MenuSuite"  -ItemType Directory -Force}
    if (!(Test-Path "$Path\Query")){ New-Item $ParentPath -Name "Query"  -ItemType Directory -Force}
        
    #$DeltaFile = "$Path\0 DELTAFILE_$VersionList.txt"
    $ExportSript = "`"$RunAsDateExe`" /movetime 26\06\2018 00:00:00 "
    $ExportSript += "`"$FinSqlExe`" command=exportobjects, "
    $ExportSript += "servername=$ServerName, username=$Username, password=$Password,"

    $WhereQuery = "WHERE [Modified] = 1 " 
    if (![string]::IsNullOrEmpty($NAVVersion)) {
        $WhereQuery += "AND [Version] LIKE '%$NAVVersion%'"
    }
    $CountRecord = "SELECT COUNT([ID]) FROM [dbo].[Object] $WhereQuery"
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameDev -Password $Password -Username $Username -Query $CountRecord # -Encrypt Optional
    $TotalRec = $result.Column1
    $SelectQuery = "SELECT * FROM [dbo].[Object] $WhereQuery"
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameDev -Password $Password -Username $Username -Query $SelectQuery # -Encrypt Optional
    foreach ($Object in $result) {
        $VLID = $Object.ID
        $VLName = $Object.Name -replace '[\W]', ' '
        $Type = $Object.Type
        $FileNameTxt = "";
        $ObjectFilter = "Type=$Type;ID=$VLID"
        switch ($Object.Type) {
            1 {
                #Table 
                $FileNameTxt = "$ParentPath\Table\Table $VLID $VLName.txt"
            }
            3 {
                #Report
                $FileNameTxt = "$ParentPath\Report\Report $VLID $VLName.txt"
            }
            5 {
                #Codeunit
                $FileNameTxt = "$ParentPath\Codeunit\Codeunit $VLID $VLName.txt"
            }
            6 {
                #XMLPort
                $FileNameTxt = "$ParentPath\XMLPort\XMLPort $VLID $VLName.txt"
            }
            7 {
                #MenuSuite
                $FileNameTxt = "$ParentPath\Menusuite\Menusuite $VLID $VLName.txt"
            }
            8 {
                #Page
                $FileNameTxt = "$ParentPath\Page\Page $VLID $VLName.txt"
            }
            9 {
                #Query
                $FileNameTxt = "$ParentPath\Query\Query $VLID $VLName.txt"
            }
            Default {}
        }

        if (![string]::IsNullOrEmpty($FileNameTxt)) {
            & cmd /c "$ExportSript filter=$ObjectFilter, database=$DatabaseNameDev, file=$FileNameTxt, ntauthentication=no"
        }

        # Progress Bar
        $o++
        $i=[math]::Round(($o/$TotalRec)*100, 0)
        Write-Progress -Activity "Exporting Objects" -Status "Progress: $i%" -PercentComplete $i
        Start-Sleep -Milliseconds 50
        
    }
    "Done"
    exit
    
}
