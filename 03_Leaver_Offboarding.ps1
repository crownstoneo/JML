# ==========================================
# Script: 03_Leaver_Offboarding.ps1 (Corrected)
# Purpose: Immediate Employee Offboarding & Session Revocation
# ==========================================

$BaseDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$TenantDomain = (Get-MgDomain | Where-Object {$_.IsDefault}).Id

# Target the employee we want to offboard (e.g., Sanne Bakker from Finance)
$TargetFirstName = "Sanne"
$TargetLastName = "Bakker"
$UPN = "$TargetFirstName.$TargetLastName@$TenantDomain"

Write-Host "Initiating Offboarding Sequence for: $UPN" -ForegroundColor Red

# 1. Verify user exists in Entra ID
$User = Get-MgUser -UserId $UPN -ErrorAction SilentlyContinue
if (-not $User) {
    Write-Host "User $UPN not found in directory!" -ForegroundColor Yellow
    return
}

# 2. Block user sign-in immediately
try {
    Update-MgUser -UserId $User.Id -AccountEnabled $false -ErrorAction Stop
    Write-Host "-> Account sign-in blocked (AccountEnabled = false)." -ForegroundColor Green
}
catch {
    Write-Host "Failed to block account: $_" -ForegroundColor Red
}

# 3. Revoke all active refresh tokens (kills current cloud sessions instantly)
try {
    Revoke-MgUserSignInSession -UserId $User.Id -ErrorAction Stop
    Write-Host "-> All active cloud sessions revoked successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to revoke sessions: $_" -ForegroundColor Red
}

# 4. Remove user from all department security groups
$MemberGroups = Get-MgUserMemberOf -UserId $User.Id
$DeptGroups = $MemberGroups | Where-Object { $_.AdditionalProperties.displayName -like "Grp-Dept-*" }

foreach ($Group in $DeptGroups) {
    $GroupName = $Group.AdditionalProperties.displayName
    try {
        # Fixed cmdlet name: Remove-MgGroupMemberDirectoryObjectByRef
        Remove-MgGroupMemberDirectoryObjectByRef -GroupId $Group.Id -DirectoryObjectId $User.Id -ErrorAction Stop
        Write-Host "-> Removed from security group: $GroupName" -ForegroundColor DarkYellow
    }
    catch {
        Write-Host "Could not remove from $GroupName : $_" -ForegroundColor Gray
    }
}

Write-Host "`nLeaver Offboarding Complete! User is disabled, signed out, and stripped of group access." -ForegroundColor Green