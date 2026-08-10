# Add-BulkUsersToADSecurityGroup
PowerShell automation for adding multiple users to Active Directory security groups in bulk. Ideal for onboarding, access provisioning, and CVAD/VDI group assignments.
ADD-BULK USERS TO ACTIVE DIRECTORY SECURITY GROUP
PowerShell Script Documentation

Script name:
Add-BulkUsersToADSecurityGroup.ps1

Prepared by:
Abscir Darman


PURPOSE: This PowerShell script automates the process of adding multiple Active
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


EXAMPLE : Five new developers require access to a Citrix VDI delivery group.

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

 
 WHAT THE SCRIPT DOES
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

 
CITRIX CVAD ACCESS MODEL
The script modifies Active Directory group membership. It does not directly
create or modify Citrix machine catalogs, delivery groups, virtual desktops,
or published applications.

Before using the script, Dev-VDI-Delivery must already be assigned to the
appropriate Citrix CVAD delivery group, desktop, or published application.

After membership is added, users may need to sign out of Windows and Citrix
Workspace and then sign back in. This refreshes their Windows security token
so that it includes the new group membership.

 
 PREREQUISITES
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

 
STRUCTURE: Create the following folder structure:

    C:\Scripts\
        Add-BulkUsersToADSecurityGroup.ps1
        Usernames.txt
        Logs\

The script creates the Logs folder automatically if it does not already exist.

 
 FILE FORMAT: Create the following file in Notepad:

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

 
 SCRIPT PARAMETERS :  UserListPath Specifies the location of the Notepad username file.
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

 
 SAFE TEST COMMAND :
Open Windows PowerShell as the delegated administrator and run:

    .\Add-BulkUsersToADSecurityGroup.ps1 `
        -UserListPath "C:\Scripts\Usernames.txt" `
        -GroupName "Dev-VDI-Delivery" `
        -WhatIf

The -WhatIf parameter simulates the operation. It displays which users would
be added but does not modify Active Directory.

Review all WhatIf, AlreadyMember, Disabled, and Failed results before continuing.

The main benefit is not only speed. The script also provides consistent
validation, prevents duplicate work, identifies disabled or missing accounts,
and produces evidence for operational and security review.

