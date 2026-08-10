<#
.SYNOPSIS
Adds multiple Active Directory users to a security group from a text file.

.DESCRIPTION
This script automates bulk Active Directory group-membership assignment during
a single PowerShell execution.

It is intended for onboarding scenarios where several employees require the
same access. For example, five newly hired developers may require access to a
Citrix CVAD virtual desktop assigned to the security group Dev-VDI-Delivery.

Instead of opening each user account in Active Directory Users and Computers
and manually editing the Member Of tab, the administrator places the users'
sAMAccountName values in a plain-text file. The file must contain one username
per line, without a heading or commas.

Example Usernames.txt:

    jdoe
    asmith
    mgarcia
    lchen
    rpatel

During execution, the script:

1. Loads the Active Directory PowerShell module.
2. Confirms that the username file exists.
3. Confirms that the specified AD group exists and is security-enabled.
4. Reads all usernames from the text file.
5. Removes blank lines and duplicate usernames.
6. Verifies that each user exists and is enabled.
7. Checks whether each user is already a direct member of the group.
8. Adds eligible users who are not already members.
9. Records an individual result for every username.
10. Exports the results to a timestamped CSV audit log.

The script supports -WhatIf, allowing the administrator to simulate proposed
membership changes without modifying Active Directory.

CITRIX CVAD ACCESS MODEL

This script modifies Active Directory group membership. It does not create or
modify Citrix machine catalogs, delivery groups, desktops, or published apps.

For CVAD access provisioning, the target AD security group must already be
assigned to the appropriate Citrix delivery group, desktop, or application.
After membership is added, users may need to sign out of Windows and Citrix
Workspace and sign back in so their security token includes the new group.

.PARAMETER UserListPath
Path to the plain-text file containing one sAMAccountName per line. Blank lines
and duplicate usernames are automatically removed.

.PARAMETER GroupName
Name, distinguished name, GUID, or SID of the target Active Directory security
group. The group must already exist and must be security-enabled.

.PARAMETER LogFolder
Folder where the timestamped CSV results log will be created.

.EXAMPLE
.\Add-BulkUsersToADSecurityGroup.ps1 -WhatIf

Simulates processing C:\Scripts\Usernames.txt and shows which users would be
added to Dev-VDI-Delivery without changing Active Directory.

.EXAMPLE
.\Add-BulkUsersToADSecurityGroup.ps1

Processes the default username file and adds eligible users to the default
Dev-VDI-Delivery security group.

.EXAMPLE
.\Add-BulkUsersToADSecurityGroup.ps1 `
    -UserListPath "C:\Scripts\NewDevelopers.txt" `
    -GroupName "Dev-VDI-Delivery"

Reads NewDevelopers.txt and adds validated users to Dev-VDI-Delivery.

.OUTPUTS
Displays and exports one result for every processed username. Status values:

Added          Membership was added successfully.
AlreadyMember  The user already has direct membership; no change was made.
Disabled       The AD account exists but is disabled; no change was made.
WhatIf         The operation was simulated; no change was made.
Failed         The username could not be processed because an error occurred.

.NOTES
Author: Abscir Darman
 

Prerequisites:
- Run from a domain-joined Windows administrative workstation or server.
- Install the RSAT Active Directory PowerShell module.
- Use an account delegated permission to modify the intended security group.
- Confirm the group is assigned to the correct Citrix resource.
- Review the username file and run with -WhatIf before production use.

Security guidance:
- Use delegated permissions rather than Domain Admin whenever possible.
- Verify the target group and approved usernames before execution.
- Retain the approved request and CSV results as change-control evidence.
- Handle membership removal through an approved offboarding process.


#>

#requires -Modules ActiveDirectory

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$UserListPath = 'C:\Scripts\Usernames.txt',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$GroupName = 'Dev-VDI-Delivery',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$LogFolder = 'C:\Scripts\Logs'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

try {
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch {
    throw "The Active Directory PowerShell module could not be loaded. Install the AD DS RSAT tools. $($_.Exception.Message)"
}

if (-not (Test-Path -LiteralPath $UserListPath -PathType Leaf)) {
    throw "The username file was not found: $UserListPath"
}

try {
    $Group = Get-ADGroup `
        -Identity $GroupName `
        -Properties GroupCategory `
        -ErrorAction Stop
}
catch {
    throw "The Active Directory group '$GroupName' was not found. $($_.Exception.Message)"
}

if ($Group.GroupCategory -ne 'Security') {
    throw "The group '$($Group.Name)' exists, but it is not a security group."
}

$UserNames = @(
    Get-Content -LiteralPath $UserListPath |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique
)

if ($UserNames.Count -eq 0) {
    throw "The username file '$UserListPath' contains no valid usernames."
}

$Results = foreach ($UserName in $UserNames) {
    try {
        $User = Get-ADUser `
            -Identity $UserName `
            -Properties Enabled, MemberOf `
            -ErrorAction Stop

        if (-not $User.Enabled) {
            [pscustomobject]@{
                Timestamp = (Get-Date).ToString('s')
                UserName  = $UserName
                GroupName = $Group.Name
                Status    = 'Disabled'
                Details   = 'The user account exists but is disabled.'
            }

            continue
        }

        if ($User.MemberOf -contains $Group.DistinguishedName) {
            [pscustomobject]@{
                Timestamp = (Get-Date).ToString('s')
                UserName  = $UserName
                GroupName = $Group.Name
                Status    = 'AlreadyMember'
                Details   = 'The user is already a direct member; no change was made.'
            }

            continue
        }

        $Target = "User '$($User.SamAccountName)' -> Group '$($Group.Name)'"

        if ($PSCmdlet.ShouldProcess($Target, 'Add Active Directory group membership')) {
            Add-ADGroupMember `
                -Identity $Group.DistinguishedName `
                -Members $User.DistinguishedName `
                -ErrorAction Stop

            [pscustomobject]@{
                Timestamp = (Get-Date).ToString('s')
                UserName  = $UserName
                GroupName = $Group.Name
                Status    = 'Added'
                Details   = 'Membership was added successfully.'
            }
        }
        else {
            [pscustomobject]@{
                Timestamp = (Get-Date).ToString('s')
                UserName  = $UserName
                GroupName = $Group.Name
                Status    = 'WhatIf'
                Details   = 'Simulation only; no change was made.'
            }
        }
    }
    catch {
        [pscustomobject]@{
            Timestamp = (Get-Date).ToString('s')
            UserName  = $UserName
            GroupName = $Group.Name
            Status    = 'Failed'
            Details   = $_.Exception.Message
        }
    }
}

if (-not (Test-Path -LiteralPath $LogFolder -PathType Container)) {
    New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
}

$LogPath = Join-Path `
    -Path $LogFolder `
    -ChildPath ("{0}-Membership-{1}.csv" -f $Group.Name, (Get-Date -Format 'yyyyMMdd-HHmmss'))

$Results |
    Export-Csv -LiteralPath $LogPath -NoTypeInformation -Encoding UTF8

$Results |
    Format-Table UserName, GroupName, Status, Details -AutoSize

Write-Host "`nProcessed $($UserNames.Count) unique username(s)." -ForegroundColor Cyan

$Results |
    Group-Object Status |
    Sort-Object Name |
    ForEach-Object {
        Write-Host ("  {0}: {1}" -f $_.Name, $_.Count)
    }

Write-Host "Results saved to: $LogPath" -ForegroundColor Cyan

if (@($Results | Where-Object Status -eq 'Failed').Count -gt 0) {
    Write-Warning 'One or more usernames failed. Review the results log.'
}
