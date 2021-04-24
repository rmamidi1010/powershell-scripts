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
