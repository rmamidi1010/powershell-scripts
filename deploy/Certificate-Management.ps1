#Setting local defaults
$script:scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
# Sourcing dependencies
if(-not(Test-Path function:\Grant-AClPermission)) { . $scriptPath\Computer-Management.ps1}