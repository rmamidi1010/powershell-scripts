function Create-LocalUser {
    param(
        [parameter(Mandatory = $true)][string] $username,
        [parameter(Mandatory = $true)][string] $password,
        [string] $fullName,
        [int[]] $flags 
    )

    $computerName = $ENV:COMPUTERNAME
    $computer = [ADSI]"WinNT://$computerName,Computer"

    $user = $computer.Create("User", $username)
    Write-Host("Created User: '$username'")
    $user.SetPassword($password)
    $user.SetInfo()
    Write-Host("'$username' password set")
    $user.FullName = if ($fullname -ne $null) { "$fullName" } else { "$username" }
    $user.SetInfo()
    Write-Host("'$username' full name set")

    if ($flags -ne $null) {
        foreach ($flag in $flags) {
            $userflags += ($flag)
        }

    $user.UserFlags = $flags
    $user.SetInfo()
    Write-Host("'$username' flags set")
    }
}


function Create-LocalGroup {
    param(
        [parameter(Mandatory = $true)][string] $groupName
    )
}

function Add-User {
    param(
        [parameter(Mandatory = $true)][string] $userName,
        [parameter(Mandatory = $true)][string] $groupName
    )
    $computerName = $ENV:COMPUTERNAME
    $group = [ADSI]"WinNT://$computerName/$groupName,group"

    $group.Add("WinNT://$computerName/$userName,user")
    Write-Host("User: '$userName' was added to the $groupName group")
}

function Get-ScheduledTasks {
    param(
        $library
    )
    $schedule = New-Object -ComObject "Schedule.Service"
    $schedule.Connect() 
    $tasks = @()
    $schedule.GetFolder($library).GetTasks(0) | % {
        $xml = $_.xml -as [Xml]
        $tasks += New-Object PSObject -Property @{
            "Name" = $_.Name
            "Path" = $_.Path
            "LastRunTime" = $_.LastRunTime
            "NextRunTime" = $_.NextRunTime
            "Actions" = ($xml.Task.Actions.Exec | % { "$($_.Command) $($_.Arguments)" }) -join "`n"
        }
    }
    return $tasks
}

## Grant Access
function Grant-ACLPermission {
    param(
        $filePath,
        $user,
        $permission = "Read",
        $allowance = "Allow",
        [switch] $recurse = $false
    )

    $acl = Get-Acl -Path $filePath

    Try 
    {
        if ($recurse) {
            $children = $user, $permission, ("ContainerInherit", "ObjectInherit"), "InheritOnly", $allowance
            $childrenRule = New-Object System.Security.AccessControl.FileSystemAccessRule $children
            $acl.AddAccessRule($childrenRule)
        }
        
        $p = $user, $permission, $allowance
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $p
        $acl.AddAccessRule($accessRule)

        Set-Acl $filePath $acl
        Write-Host("ACL successfully updated on $filePath")
    }
    Catch
    {
        Write-ERROR ("[ERROR] Unable to modify $permission access to $filePath for $user on $ENV:COMPUTERNAME. Please Investigate.")
    }
}
