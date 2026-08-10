# Add-BulkUsersToADSecurityGroup
PowerShell automation for adding multiple users to Active Directory security groups in bulk. Ideal for onboarding, access provisioning, and CVAD/VDI group assignments.
ADD-BULK USERS TO ACTIVE DIRECTORY SECURITY GROUP
PowerShell Script Documentation

Script name:
Add-BulkUsersToADSecurityGroup.ps1

Prepared by:
Abscir Darman

======================================================================
1. PURPOSE
======================================================================

This PowerShell script automates the process of adding multiple Active
Directory users to one security group during a single execution.

The script is useful when several new employees require the same access. For
example, five newly hired developers may need access to a Citrix CVAD virtual
desktop assigned to the Active Directory security group Dev-VDI-Delivery.

Without the script, an administrator would normally open each user account in
Active Directory Users and Computers, select the Member Of tab, add the group,
and repeat the procedure for every employee.

With this script, the administrator places all approved usernames in a Notepad
text file and runs one PowerShell command. The script processes every username,
validates the accounts, adds eligible users, skips existing members, and writes
an audit log.

"Bulk" or "at once" means that the complete username list is processed through
one script execution. Each user is still validated and recorded individually,
so one invalid username does not prevent the remaining valid users from being
processed.

======================================================================
2. EXAMPLE BUSINESS SCENARIO
======================================================================

Five new developers require access to a Citrix VDI delivery group.

Target Active Directory security group:

    Dev-VDI-Delivery

Approved usernames:

    jdoe
    asmith
    mgarcia
    lchen
    rpatel

The administrator creates Usernames.txt, enters one username per line, tests
the script with -WhatIf, and then performs the approved production run.

======================================================================
3. WHAT THE SCRIPT DOES
======================================================================

During execution, the script performs the following operations:

1. Loads the Active Directory PowerShell module.
2. Confirms that the username text file exists.
3. Confirms that the specified Active Directory group exists.
4. Confirms that the target group is security-enabled.
5. Reads every username from the Notepad text file.
6. Removes blank lines and duplicate usernames.
7. Verifies that each username exists in Active Directory.
8. Checks whether each account is enabled.
9. Checks whether each user is already a direct member of the group.
10. Adds eligible users who are not already members.
11. Skips disabled accounts and existing members.
12. Records an individual result for every username.
13. Exports the results to a timestamped CSV audit log.

======================================================================
4. CITRIX CVAD ACCESS MODEL
======================================================================

The script modifies Active Directory group membership. It does not directly
create or modify Citrix machine catalogs, delivery groups, virtual desktops,
or published applications.

Before using the script, Dev-VDI-Delivery must already be assigned to the
appropriate Citrix CVAD delivery group, desktop, or published application.

After membership is added, users may need to sign out of Windows and Citrix
Workspace and then sign back in. This refreshes their Windows security token
so that it includes the new group membership.

======================================================================
5. PREREQUISITES
======================================================================

- Run the script from a domain-joined Windows administrative workstation or
  server.
- Install the Active Directory PowerShell module through RSAT.
- Use an account with delegated permission to modify the target security group.
- Confirm that the target group exists and is security-enabled.
- Confirm that the target group is assigned to the correct Citrix resource.
- Review and approve all usernames before the production run.
- Use -WhatIf before making changes in production.

The administrator does not need Domain Admin rights when the appropriate group
management permission has been delegated.

======================================================================
6. RECOMMENDED FOLDER STRUCTURE
======================================================================

Create the following folder structure:

    C:\Scripts\
        Add-BulkUsersToADSecurityGroup.ps1
        Usernames.txt
        Logs\

The script creates the Logs folder automatically if it does not already exist.

======================================================================
7. USERNAME FILE FORMAT
======================================================================

Create the following file in Notepad:

    C:\Scripts\Usernames.txt

Enter one Active Directory sAMAccountName per line:

    jdoe
    asmith
    mgarcia
    lchen
    rpatel

Important formatting requirements:

- Do not add a heading such as UserName or SamAccountName.
- Do not separate usernames with commas.
- Do not put several usernames on one line.
- Blank lines are allowed and will be ignored.
- Duplicate usernames are automatically removed.
- Use the users' normal domain logon names, not their display names.

======================================================================
8. SCRIPT PARAMETERS
======================================================================

UserListPath
    Specifies the location of the Notepad username file.

    Default:
    C:\Scripts\Usernames.txt

GroupName
    Specifies the Active Directory security group to which the users will be
    added.

    Default:
    Dev-VDI-Delivery

LogFolder
    Specifies the folder in which the timestamped CSV audit log will be saved.

    Default:
    C:\Scripts\Logs

======================================================================
9. SAFE TEST COMMAND
======================================================================

Open Windows PowerShell as the delegated administrator and run:

    .\Add-BulkUsersToADSecurityGroup.ps1 `
        -UserListPath "C:\Scripts\Usernames.txt" `
        -GroupName "Dev-VDI-Delivery" `
        -WhatIf

The -WhatIf parameter simulates the operation. It displays which users would
be added but does not modify Active Directory.

Review all WhatIf, AlreadyMember, Disabled, and Failed results before continuing.

======================================================================
10. PRODUCTION COMMAND
======================================================================

After reviewing the -WhatIf results and receiving change approval, run:

    .\Add-BulkUsersToADSecurityGroup.ps1 `
        -UserListPath "C:\Scripts\Usernames.txt" `
        -GroupName "Dev-VDI-Delivery"

The script will add eligible users and save a timestamped results file under:

    C:\Scripts\Logs

Example log filename:

    Dev-VDI-Delivery-Membership-20260810-153000.csv

======================================================================
11. RESULT STATUS MEANINGS
======================================================================

Added
    The user was successfully added to the security group.

AlreadyMember
    The user is already a direct member. No change was required.

Disabled
    The user account exists but is disabled. No membership was added.

WhatIf
    The operation was simulated. Active Directory was not modified.

Failed
    The username could not be processed. Possible causes include an invalid
    username, insufficient permissions, domain-controller connectivity, or an
    Active Directory error.

======================================================================
12. VERIFY GROUP MEMBERSHIP
======================================================================

To display the direct members of Dev-VDI-Delivery, run:

    Get-ADGroupMember -Identity "Dev-VDI-Delivery" |
        Sort-Object Name |
        Select-Object Name, SamAccountName, ObjectClass

To verify one user, run:

    Get-ADUser -Identity "jdoe" -Properties MemberOf |
        Select-Object -ExpandProperty MemberOf

======================================================================
13. VIEW THE BUILT-IN SCRIPT HELP
======================================================================

The PowerShell script contains comment-based help. Use these commands:

Full documentation:

    Get-Help .\Add-BulkUsersToADSecurityGroup.ps1 -Full

Examples only:

    Get-Help .\Add-BulkUsersToADSecurityGroup.ps1 -Examples

GroupName parameter help:

    Get-Help .\Add-BulkUsersToADSecurityGroup.ps1 -Parameter GroupName

======================================================================
14. SECURITY AND CHANGE-CONTROL GUIDANCE
======================================================================

- Use delegated group-management permissions rather than Domain Admin.
- Verify the target group name before running the production command.
- Confirm that every username has an approved business request.
- Retain the approved request, Usernames.txt, and results CSV as evidence.
- Protect the username file and audit log according to company policy.
- Do not use the onboarding script as an unapproved offboarding method.
- Review failed accounts individually before rerunning the script.

======================================================================
15. ROLLBACK
======================================================================

If an account was added incorrectly, obtain approval and remove it with:

    Remove-ADGroupMember `
        -Identity "Dev-VDI-Delivery" `
        -Members "jdoe" `
        -Confirm:$false

Record all rollback actions in the change or access-request ticket.

======================================================================
16. OPERATIONAL SUMMARY
======================================================================

The script converts a repetitive Active Directory task into a controlled bulk
workflow:

    Prepare approved username list
              -> Run -WhatIf
              -> Review validation results
              -> Run production command
              -> Review CSV audit log
              -> Verify Citrix access

The main benefit is not only speed. The script also provides consistent
validation, prevents duplicate work, identifies disabled or missing accounts,
and produces evidence for operational and security review.

