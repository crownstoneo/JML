<h1>Entra ID Project: Automated Joiner-Mover-Leaver (JML) Identity Lifecycle</h1>

<h2>Objective</h2>
Automate employee onboarding, department transfers, security group RBAC, and immediate offboarding in Microsoft Entra ID using PowerShell and the Microsoft Graph SDK.
<br />

<h2>Environments Used</h2>
- <b>Microsoft Entra ID (Azure AD) Tenant</b>
<br />
- <b>PowerShell Environment</b>
<br />
- <b>HR CSV Data Feed (Employees_Input.csv)</b>
<br />

<h2>Tools Used</h2>
- <b>Microsoft Graph PowerShell SDK</b> (New-MgUser, Update-MgUser, Get-MgUser, Get-MgDomain, Get-MgGroup, New-MgGroupMember, Remove-MgGroupMemberDirectoryObjectByRef, Revoke-MgUserSignInSession)
<br />
- <b>PowerShell Core</b> (Import-Csv, foreach, try/catch, Test-Path)
<br />
- <b>Git & GitHub</b>
<br />

<h2>Methodology</h2>
- <b>Automated Joiner Provisioning (01_Joiner_Provisioning.ps1):</b> Validated HR CSV input paths, dynamically fetched the tenant's primary domain, generated standardized UPNs, and provisioned new Entra ID accounts with randomized temporary passwords and forced password resets on first sign-in.
<br />
- <b>Dynamic Department RBAC (01b_Assign_Department_Groups.ps1):</b> Verified whether department security groups (Grp-Dept-&lt;Department&gt;) existed, created missing groups dynamically, and assigned new hires to their respective groups.
<br />
- <b>Mover Lifecycle Transfers (02_Mover_Lifecycle.ps1):</b> Updated user department attributes in Entra ID, removed transferred employees from legacy department security groups, and added them to their new target department groups.
<br />
- <b>Leaver Offboarding & Session Revocation (03_Leaver_Offboarding.ps1):</b> Blocked user sign-in immediately (-AccountEnabled $false), revoked all active cloud refresh tokens via Revoke-MgUserSignInSession, and stripped departing users from all department security groups.
<br />
- <b>Engineered Fault Tolerance:</b> Wrapped directory operations in try/catch blocks with -ErrorAction Stop so missing users or malformed rows log clear warnings without crashing batch execution.
<br />

<h2>Evidence</h2>
<b>Joiner Provisioning & Group Assignment:</b> 
<br />

<img alt="Joiner Provisioning Terminal Output" src="https://github.com/user-attachments/assets/fae4a9f8-42b7-4906-8e2b-1e550ccbca0f" />
<br />
<br />
<b>Mover Department & RBAC Transition:</b> 
<br />

<img alt="Mover Lifecycle Entra Audit log result" src="https://github.com/user-attachments/assets/e9f94952-8782-454c-8282-06f9611ea7bd" />
<br />
<br />
<b>Leaver Offboarding & Entra Audit Logs:</b> 
<br />


<img alt="Leaver Offboarding Output" src="https://github.com/user-attachments/assets/1942463e-33e8-41ef-b51d-0044b15ec260" />

<h2>Findings</h2>
Manual identity administration introduces human error, privilege creep during role transfers, and dangerous delays in revoking access when employees leave. Automated PowerShell workflows standardize provisioning and enforce immediate offboarding.
<br />

<h2>Business & Compliance Impact</h2>
- <b>Mitigates Orphan Account Risk (NIS2 / ISO 27001):</b> Disabling accounts (-AccountEnabled $false) and revoking active refresh tokens closes the security window between HR termination and IT execution.
<br />
- <b>Enforces Least Privilege (GDPR / AVG):</b> Rotating department security group memberships during role changes prevents privilege creep across departments.
<br />
- <b>Reduces Helpdesk Overhead:</b> Replaces repetitive manual account creation and group management with repeatable, auditable batch scripts.
<br />

<h2>Lessons Learned</h2>
- Using -ErrorAction Stop inside try/catch blocks is essential in bulk directory scripts so a single missing user or bad CSV row triggers clean error handling without halting critical offboarding runs.
<br />
- Managing security group removals via Remove-MgGroupMemberDirectoryObjectByRef ensures clean RBAC transitions when employees transfer departments or leave the organization.
