# Entra ID Project: Automated Joiner-Mover-Leaver (JML) Identity Lifecycle

## Objective
Automate employee onboarding, department transfers, security group RBAC, and immediate offboarding in Microsoft Entra ID using PowerShell and the Microsoft Graph SDK.

## Environments & Prerequisites
* **Identity Provider:** Microsoft Entra ID (Azure AD) Lab Tenant
* **Runtime:** PowerShell Core (7+) with the `Microsoft.Graph` PowerShell SDK
* **Data Source:** Simulated HR CSV Feed (`Employees_Input.csv`)
* **Required Microsoft Graph Permissions (Least Privilege):**
  * `User.ReadWrite.All` (create, update, disable users, and revoke sign-in sessions)
  * `Group.ReadWrite.All` (verify and create department security groups)
  * `GroupMember.ReadWrite.All` (assign and remove security group memberships)
  * `Domain.Read.All` (dynamically retrieve the tenant's primary domain)

## Tools & Cmdlets Used
* **Microsoft Graph PowerShell SDK:** `New-MgUser`, `Update-MgUser`, `Get-MgUser`, `Get-MgDomain`, `Get-MgGroup`, `New-MgGroup`, `New-MgGroupMember`, `Remove-MgGroupMemberDirectoryObjectByRef`, `Revoke-MgUserSignInSession`
* **PowerShell Core:** `Import-Csv`, `foreach`, `try/catch`, `Test-Path`, `-ErrorAction Stop`
* **Version Control:** Git & GitHub

## Sample Input (`Employees_Input.csv`)
```csv
FirstName,LastName,Department,JobTitle,StartDate
Emma,VanDijk,Engineering,Cloud Engineer,2026-06-01
Lars,DeJong,Security,SecOps Analyst,2026-06-01
Sanne,Bakker,Finance,Financial Analyst,2026-06-01
```

## Methodology
* **Automated Joiner Provisioning (`01_Joiner_Provisioning.ps1`):** Validated HR CSV input paths, dynamically fetched the tenant's primary domain, generated standardized UPNs, and provisioned new Entra ID accounts with randomized temporary passwords and forced password resets on first sign-in.
* **Dynamic Department RBAC (`01b_Assign_Department_Groups.ps1`):** Verified whether department security groups (`Grp-Dept-<Department>`) existed, created missing groups dynamically, and assigned new hires to their respective groups.
* **Mover Lifecycle Transfers (`02_Mover_Lifecycle.ps1`):** Updated user department attributes in Entra ID, removed transferred employees from legacy department security groups, and added them to their new target department groups.
* **Leaver Offboarding & Session Revocation (`03_Leaver_Offboarding.ps1`):** Blocked user sign-in immediately (`-AccountEnabled $false`), revoked all active cloud refresh tokens via `Revoke-MgUserSignInSession`, and stripped departing users from all department security groups.
* **Engineered Fault Tolerance:** Wrapped directory operations in `try/catch` blocks with `-ErrorAction Stop` so missing users or malformed rows log clear warnings without halting batch execution.

## Evidence

### Joiner Provisioning & Group Assignment
![Joiner Provisioning Terminal Output](https://github.com/user-attachments/assets/86dc2f67-70f3-4d0b-b1ac-2b0035fc802e)

### Mover Department & RBAC Transition
![Mover Lifecycle Entra Audit log result](https://github.com/user-attachments/assets/e9f94952-8782-454c-8282-06f9611ea7bd)

### Leaver Offboarding & Entra Audit Logs
![Leaver Offboarding Output](https://github.com/user-attachments/assets/1942463e-33e8-41ef-b51d-0044b15ec260)

## Findings
Manual identity administration introduces human error, privilege creep during role transfers, and dangerous delays in revoking access when employees leave. Automated PowerShell workflows standardize provisioning and enforce immediate offboarding.

## Security & Governance Value
* **Mitigates Orphan Account Risk (Supports ISO 27001 / NIS2 Access Control):** Disabling accounts (`-AccountEnabled $false`) and revoking active refresh tokens closes the security window between HR termination and IT execution.
* **Enforces Least Privilege (Supports GDPR / AVG Data Minimization):** Rotating department security group memberships during role changes prevents privilege creep across departments.
* **Reduces Helpdesk Overhead:** Replaces repetitive manual account creation and group management with repeatable, auditable batch scripts.

## Lessons Learned
* Using `-ErrorAction Stop` inside `try/catch` blocks is essential in bulk directory scripts so a single missing user or bad CSV row triggers clean error handling without halting critical offboarding runs.
* Managing security group removals via `Remove-MgGroupMemberDirectoryObjectByRef` ensures clean RBAC transitions when employees transfer departments or leave the organization.
