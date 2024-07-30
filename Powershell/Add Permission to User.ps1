import-module "C:\Program Files\Microsoft Dynamics NAV\90\Service\NavAdminTool.ps1"
Import-Module "C:\Program Files (x86)\Microsoft Dynamics NAV\90\RoleTailored Client\Microsoft.Dynamics.Nav.Model.Tools.psd1"

New-NAVServerUserPermissionSet Dynamicsnav90 -UserName jessie.moyano -PermissionSetId Super