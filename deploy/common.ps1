$INTERNAL_BUILD = "\\fileshares01\Shared\Deliverables\Internal\Builds"
$EXTERNAL_RELEASE = "\\fileshare01\Shared\Deliverables\External\Releases"
$LOCAL_DROP = "$HOME\Build"

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
if (-not (Test-Path function:\Install-Font)) { Import-Module -Name $scriptPath\ext\pswinglue.0.5.0\PSWinGlue.psm1 -DisableNameChecking }

Add-Type -AssemblyName System.IO.Compression.FileSystem

$global:drives = Get-PSDrive -PSProvider "FileSystem" | where {$_.Free -ne $null}
$global:stats = @{}
$global:notes = @()

function fail-error {
    param(
        [string] $message
    )
    throw $message
    Exit 1
}

function Unzip
{
    param(
        [string]$zipfile, 
        [string]$outpath,
        [bool]$overwrite = $true
    )
    $src = Resolve-Path $zipfile
    $trg = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outpath)

    if ($PSVERSIONTABLE.PSVersion.Major -lt 5) { 
        Add-Type -AssemblyName System.IO.Compression.FileSystem 
        # Since PS4.0 does not support overwrite during unzipping, the calling code need to manually taking care of it first
        # This is required for most of our 2008 R2 lab servers
        [System.IO.Compression.ZipFile]::ExtractToDirectory($src, $trg, $overwrite)
    } 
    else { 
        # 2016 Srv all have PS v5.0 installed by default, so overwrite switch is always on
        Expand-Archive -Path "$src" -DestinationPath "$trg" -Force 
    } 
}

function Assemble-Config {
    param(
        [parameter(Mandatory=$true)][string[]] $base_configs,
        [string[]] $over_configs = @()
    )

    $global:configs = New-Object System.Collections.Stack

    foreach($file in $base_configs) {
        if (-not(Test-Path $file)) {
            $message = "$file not found! Proceeding with warnings..."
            Write-Host("$message") -foregroundcolor "yellow"
            $notes += $message
        }
        else {
            $config_obj = Load-Config $file
            $configs.push($config_obj)
        }
    }

    foreach($file in $over_configs) {
        if (-not(Test-Path $file)) {
            $message = "$file not found! Proceeding with warnings..."
            Write-Host("$message") -foregroundcolor "yellow"
            $notes += $message
        }
        else {
            $config_obj = Load-Config $file
            $configs.push($config_obj)
        }
    }

    $resolved = New-Object System.Collections.Stack

    foreach($file in $base_configs) {
        if (-not(Test-Path $file)) {
            $message = "$file not found! Proceeding with warnings..."
            Write-Host("$message") -foregroundcolor "yellow"
            $notes += $message
        }
        else {
            $config_obj = ((Get-Content $file -raw -Encoding utf8).replace('$(computername)', "$ENV:COMPUTERNAME").replace('$(dns_domain)', (Get-Config 'dns_domain'))) -Join "`n" | ConvertFrom-Json
            $resolved.push($config_obj)
        }
    }

    foreach($file in $over_configs) {
        if (-not(Test-Path $file)) {
            $message = "$file not found! Proceeding with warnings..."
            Write-Host("$message") -foregroundcolor "yellow"
            $notes += $message
        }
        else {
            $config_obj = ((Get-Content $file -raw -Encoding utf8).replace('$(computername)', "$ENV:COMPUTERNAME").replace('$(dns_domain)', (Get-Config 'dns_domain'))) -Join "`n" | ConvertFrom-Json
            $resolved.push($config_obj)
        }
    }

    $global:configs = $resolved
}

function Load-Config {
    param(
        [parameter(Mandatory=$true)][string] $config_json
    )
    if ($PSVERSIONTABLE.PSVersion.Major -lt 4) {
        Write-Host("Windows PowerShell Version 4.0 or greater is required to read from the .json configuration file.") -foregroundcolor "Red"
        Write-Host("This console's current version is " + $PSVERSIONTABLE.PSVersion + ".") -foregroundcolor "Red"
        Exit 1
    }
    try {
        $config_json = Resolve-Path $config_json
        Write-Host("Loading deployment configuration from $config_json")
        return (Get-Content $config_json -Encoding utf8) -Join "`n" | ConvertFrom-Json 
    }
    catch [Exception] {
        Write-Host("Could not load deployment configuration from $config_json, please check the files formatting.") -foregroundcolor "Red"
    }
}


