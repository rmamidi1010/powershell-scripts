Param(
  [Alias("c")]
  [switch] $commit = $false,
  [Alias("i")]
  [switch] $ignoreValidation = $false,
  [Alias("r")]
  [switch] $reportOnly = $false,
  [Int32] $maxConnection = 12, 
  [Int32] $maxIoThreads = 100,
  [Int32] $minIoThreads = 20,
  [Int32] $maxWorkerThreads = 100,
  [Int32] $minWorkerThreads = 20,
  [Int32] $minFreeThreads = 88,
  [Int32] $minLocalRequestFreeThreads = 76,
  [Alias("?")]
  [switch] $help = $false
)

$isValid = $true

# help display
if ($help) {
    try {
      $man = Get-Content(".\UpdateMachineConfigUsage.txt") -raw
      Write-Host ($man)
    }
    catch [Exception] {
      Write-Host ("UpdateMachineConfigUsage.txt not found...")
    }
    finally {
      exit 0
    }
  }

doMaxConnection = $PSBoundParameters.ContainsKey("maxConnection")
$doMaxIoThreads = $PSBoundParameters.ContainsKey("maxIoThreads")
$doMinIoThreads = $PSBoundParameters.ContainsKey("minIoThreads")
$doMaxWorkerThreads = $PSBoundParameters.ContainsKey("maxWorkerThreads")
$doMinWorkerThreads = $PSBoundParameters.ContainsKey("minWorkerThreads")
$doMinFreeThreads = $PSBoundParameters.ContainsKey("minFreeThreads")
$doMinLocalRequestFreeThreads = $PSBoundParameters.ContainsKey("minLocalRequestFreeThreads")

#get initial config sections
$numberOfCores = Get-WmiObject -class win32_processor numberOfCores | Select-Object -ExpandProperty numberOfCores | ForEach-Object {$result+=$_} -Begin {$result=$null} -End {$result}

$machineConfig = [System.Configuration.ConfigurationManager]::OpenMachineConfiguration()

$processModel = $machineConfig.SectionGroups['system.web'].ProcessModel
$httpRuntime = $machineConfig.SectionGroups['system.web'].HttpRuntime
$connectionManagement = $machineConfig.SectionGroups['system.net'].ConnectionManagement

#write original values
Write-Host ('Existing Values:')
Write-Host ("              MaxWorkerThreads: " + $processModel.MaxWorkerThreads) -ForegroundColor Gray
Write-Host ("              MinWorkerThreads: " + $processModel.MinWorkerThreads) -ForegroundColor Gray
Write-Host ("                  MaxIoThreads: " + $processModel.MaxIOThreads) -ForegroundColor Gray
Write-Host ("                  MinIoThreads: " + $processModel.MinIOThreads) -ForegroundColor Gray
Write-Host ("                MinFreeThreads: " + $httpRuntime.MinFreeThreads) -ForegroundColor Gray
Write-Host ("    MinLocalRequestFreeThreads: " + $httpRuntime.MinLocalRequestFreeThreads) -ForegroundColor Gray
Write-Host ("                 MaxConnection: " + $connectionManagement.ConnectionManagement.MaxConnection) -ForegroundColor Gray
Write-Host ("")

if ($reportOnly) {
    exit 0
}

# do input validation
if ($maxConnection -lt 1) {
    $isValid = $false
    Write-Host "WARNING: Validation: maxConnection value $maxConnection is less than 1" -ForegroundColor Yellow
}
if ($maxIoThreads -lt 1) {
    $isValid = $false
    Write-Host "WARNING: Validation: maxIoThreads value $maxIoThreads is less than 1" -ForegroundColor Yellow
}
if ($minIoThreads -lt 1) {
    $isValid = $false
    Write-Host "WARNING: Validation: minIoThreads value $minIoThreads is less than 1" -ForegroundColor Yellow
}
if ($maxWorkerThreads -lt 1) {
    $isValid = $false
    Write-Host "WARNING: Validation: maxWorkerThreads value $maxWorkerThreads is less than 1" -ForegroundColor Yellow
}
if ($minWorkerThreads -lt 1) {
    $isValid = $false
    Write-Host "WARNING: Validation: minWorkerThreads value $minWorkerThreads is less than 1" -ForegroundColor Yellow
}
if ($minFreeThreads -lt 1) {
    $isValid = $false
    Write-Host "WARNING: Validation: minFreeThreads value $minFreeThreads is less than 1" -ForegroundColor Yellow
}
if ($minLocalRequestFreeThreads -lt 1) {
    $isValid = $false
    Write-Host "WARNING: Validation: minLocalRequestFreeThreads value $minLocalRequestFreeThreads is less than 1" -ForegroundColor Yellow
}
if ($maxWorkerThreads -lt $minWorkerThreads) {
    $isValid = $false
    Write-Host "WARNING: Validation: maxWorkerThreads value $maxWorkerThreads is less than minWorkerThreads value $minWorkerThreads" -ForegroundColor Yellow
}
if ($maxIoThreads -lt $minIoThreads) {
    $isValid = $false
    Write-Host "WARNING: Validation: maxIoThreads value $maxIoThreads is less than minIoThreads value $minIoThreads" -ForegroundColor Yellow
}
if ($minFreeThreads -lt $minLocalRequestFreeThreads) {
    $isValid = $false
    Write-Host "WARNING: Validation: minFreeThreads value $minFreeThreads is less than minLocalRequestFreeThreads value $minLocalRequestFreeThreads" -ForegroundColor Yellow
}

#do updates
if ($doMaxIoThreads -or $doMinIoThreads -or $doMaxWorkerThreads -or $doMinWorkerThreads) {
    $processModel.SectionInformation.RevertToParent()
    if ($doMaxWorkerThreads) {
        $processModel.MaxWorkerThreads = $maxWorkerThreads
    }
    if ($doMinWorkerThreads) {
        $processModel.MinWorkerThreads = $minWorkerThreads
    }
    if ($doMaxIoThreads) {
        $processModel.MaxIOThreads = $maxIoThreads
    }
    if ($doMinIoThreads) {
    $processModel.MinIOThreads = $minIoThreads
    }
}

if ($doMinFreeThreads) {
    $httpRuntime.MinFreeThreads = $minFreeThreads * $numberOfCores
}
if ($doMinLocalRequestFreeThreads) {
    $httpRuntime.MinLocalRequestFreeThreads = $minLocalRequestFreeThreads * $numberOfCores
}
if ($doMaxConnection) {
    $connectionManagement.ConnectionManagement.Add((New-Object System.Net.Configuration.ConnectionManagementElement *, ($maxConnection * $numberOfCores)))
}

#show new values
Write-Host ('New Values:')
Write-Host ("              MaxWorkerThreads: " + $processModel.MaxWorkerThreads) -ForegroundColor $(if ($doMaxWorkerThreads) {"Green"} else {"Gray"})
Write-Host ("              MinWorkerThreads: " + $processModel.MinWorkerThreads) -ForegroundColor $(if ($doMinWorkerThreads) {"Green"} else {"Gray"})
Write-Host ("                  MaxIoThreads: " + $processModel.MaxIOThreads) -ForegroundColor $(if ($doMaxIoThreads) {"Green"} else {"Gray"})
Write-Host ("                  MinIoThreads: " + $processModel.MinIOThreads) -ForegroundColor $(if ($doMinIoThreads) {"Green"} else {"Gray"})
Write-Host ("            [*] MinFreeThreads: " + $httpRuntime.MinFreeThreads + " ($minFreeThreads * $numberOfCores)") -ForegroundColor $(if ($doMinFreeThreads) {"Green"} else {"Gray"})
Write-Host ("[*] MinLocalRequestFreeThreads: " + $httpRuntime.MinLocalRequestFreeThreads + " ($minLocalRequestFreeThreads * $numberOfCores)") -ForegroundColor $(if ($doMinLocalRequestFreeThreads) {"Green"} else {"Gray"})
Write-Host ("             [*] MaxConnection: " + $connectionManagement.ConnectionManagement.MaxConnection + " ($maxConnection * $numberOfCores)") -ForegroundColor $(if ($doMaxConnection) {"Green"} else {"Gray"})
Write-Host ("Note: [*] => value adjusted for scaling to number of available cores") -ForegroundColor Gray
Write-Host ("")

#save updates
if ($commit) {
    $doWrite = $true
    if (-not $isValid) {
        if ($ignoreValidation) {
            Write-Host ("WARNING: new values were flagged as not valid, but -ignoreValidation was specified") -ForegroundColor Yellow
        } else {
            Write-Host ("WARNING: new values were flagged as invalid and will not be written back to machine.config.") -ForegroundColor Yellow
            $doWrite = $false
        }
    }
    if ($doWrite) {
        Write-Host ("Writing to machine.config...")
        $machineConfig.Save()
        Write-Host ("Written to machine.config.") -ForegroundColor Green
    }
} else {
    Write-Host ("-commit not specified, changes will not be saved") -ForegroundColor Yellow
}
