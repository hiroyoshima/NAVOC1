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
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameDev -Password $Password -Username $Username -Query $SelectQuery -Encrypt Optional
    if($result.Result -eq 0){
        Throw "There's no Version List found using the Version $VersionList" 
    }
    #Check if project path is valid
    if (!(Test-Path $Path)) { Throw "$Path path cannot be found." }

    # New-Item $Path -Name "Development"  -ItemType Directory -Force
    New-Item $Path -Name "Live"  -ItemType Directory -Force
    New-Item $Path -Name "Logs"  -ItemType Directory -Force

    #Check if RunAsDate file
    if (!(Test-Path $RunAsDateExe)) { Throw "$RunAsDateExe RunAsDate.exe file cannot be found." }
    
    # Check finsql.exe file
    if (!(Test-Path $FinSqlExe)) { Throw "$FinSqlExe finsql.exe file cannot be found." }

    #$DeltaFile = "$Path\0 DELTAFILE_$VersionList.txt"
    $ExportSript = "`"$RunAsDateExe`" /movetime 26\06\2018 00:00:00 "
    $ExportSript += "`"$FinSqlExe`" command=exportobjects, "
    $ExportSript += "servername=$ServerName, username=$Username, password=$Password, filter=Version List=*$VersionList,"

    #Export NAV Objects Command
    & cmd /c "$ExportSript database=$DatabaseNameDev, file=$Path\DEV $VersionList.txt, ntauthentication=no, logfile=$Path\Logs\DEV $VersionList.txt"
    if ($ExportDevFob) { # Allow Export DevFob
        & cmd /c "$ExportSript database=$DatabaseNameDev, file=$Path\DEV $VersionList.fob, ntauthentication=no" 
    }

    #Update the Version List from Development to Live
    if ($DatabaseNameLive -ne "") {
        $SelectQuery = "SELECT * FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
        $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameDev -Password $Password -Username $Username -Query $SelectQuery -Encrypt Optional 

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
            Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseNameLive -Password $Password -Username $Username -Query $UpdateQuery -Encrypt Optional 

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

function Import-Nav-Objects {
    param (
        # File  path of object to import
        [Parameter(Mandatory = $true)]
        [string]
        $File,

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

        # Database name 
        [Parameter(Mandatory = $true)]
        [string]
        $Database,

        # RunAsDate Exe File
        [Parameter(Mandatory = $true)]
        [String]
        $RunAsDateExe,

        # FinSQL Exe File
        [Parameter(Mandatory = $true)]
        [String]
        $FinSqlExe
    )

    #Check if project path is valid
    $File = [IO.Path]::ChangeExtension($File, [NullString]::Value)
    $File = "$File.fob"

    if (!(Test-Path $File)) { Throw "$File path cannot be found." }
    
    # finsql.exe command=importobjects, file=<importfile>, [servername=<server>,] [database=<database>,] [logfile=<path and filename>,] [importaction=<default|overwrite|skip|0|1|2>,] [username=<username>,] [password=<password>,] [ntauthentication=<yes|no|1|0>,] [synchronizeschemachanges=<yes|no|force>,] [navservername=<server name>,] [navserverinstance=<instance>,] [navservermanagementport=<port>,] [tenant=<tenant ID>]
    $ImportScript = "`"$RunAsDateExe`" /movetime 26\06\2018 00:00:00 "
    $ImportScript += "`"$FinSqlExe`" command=importobjects, "
    $ImportScript += " file=$File, logfile=C:\importlog.txt, servername=$ServerName, database=`"$Database`", ImportAction=overwrite, username=$Username, password=$Password, ntauthentication=no, synchronizeschemachanges=force"

    & cmd /c "$ImportScript"
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
    $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseOrig -Password $Password -Username $Username -Query $SelectQuery -Encrypt Optional
    if($result.Result -eq 0){
        Throw "There's no Version List found using the Version $VersionList" 
    }
    #Check if project path is valid
    if (!(Test-Path $Path)) { Throw "$Path path cannot be found." }

    #Check if RunAsDate file
    if (!(Test-Path $RunAsDateExe)) { Throw "$RunAsDateExe RunAsDate.exe file cannot be found." }
    
    # Check finsql.exe file
    if (!(Test-Path $FinSqlExe)) { Throw "$FinSqlExe finsql.exe file cannot be found." }

    #$DeltaFile = "$Path\0 DELTAFILE_$VersionList.txt"
    $ExportSript = "`"$RunAsDateExe`" /movetime 26\06\2018 00:00:00 "
    $ExportSript += "`"$FinSqlExe`" command=exportobjects, "
    $ExportSript += "servername=$ServerName, username=$Username, password=$Password, filter=Version List=*$VersionList,"

    $ModifiedPath = "$Path\ModifiedObject.txt"
    $OriginalPath = "$Path\OriginalObject.txt"

    #Export NAV Objects Command
    & cmd /c "$ExportSript database=$DatabaseOrig, file=$ModifiedPath, ntauthentication=no, logfile=$Path\Logs\DEV $VersionList.txt"

    #Update the Version List from Development to Live
        $SelectQuery = "SELECT * FROM [dbo].[Object] WHERE [Version List] LIKE '%$VersionList%'"
        $result = Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseOrig -Password $Password -Username $Username -Query $SelectQuery -Encrypt Optional 

        foreach ($Object in $result) {
            $VLVersionList = $Object."Version List"
            $VLType = $Object.Type
            $VLID = $Object.ID

            # Update the Version List of Object on the Live Database
            $UpdateQuery = "UPDATE Object SET [Version List] = '$VLVersionList' WHERE Type = $VLType AND ID = $VLID"
            Invoke-Sqlcmd -ServerInstance $ServerName -Database $DatabaseOld -Password $Password -Username $Username -Query $UpdateQuery -Encrypt Optional 
        }

        & cmd /c "$ExportSript database=$DatabaseOld, file=$OriginalPath, ntauthentication=no, logfile=$Path\Logs\LIVE $VersionList.txt"
    
        # Compare-NAVApplicationObject -OriginalPath $OriginalPath -ModifiedPath $ModifiedPath -DeltaPath "$Path\Delta $VersionList.txt" -Force;
        # Remove-Item -Path $OriginalPath -Force;
        # Remove-Item -Path $ModifiedPath -Force;
}