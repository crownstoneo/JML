# ==========================================
# Script: 02_Mover_Lifecycle.ps1 (Corrected)
# Purpose: Handle Employee Department Transfers (Mover Workflow)
# ==========================================

$BaseDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$CsvPath = Join-Path $BaseDir "Employees_Input.csv"

if (-not (Test-Path $CsvPath)) {
    Write-Host "Error: Cannot find $CsvPath." -ForegroundColor Red
    return
}

$Employees = Import-Csv -Path $CsvPath
$TenantDomain = (Get-MgDomain | Where-Object {$_.IsDefault}).Id

Write-Host "Starting Mover / Department Transfer Engine..." -ForegroundColor Cyan

# For demonstration, let's pick Lars DeJong and simulate a transfer to Engineering
$TargetFirstName = "Lars"
$TargetLastName = "DeJong"
$NewDepartment = "Engineering" # Lars was originally in Security!

$UPN = "$TargetFirstName.$TargetLastName@$TenantDomain"

# 1. Verify user exists
$User = Get-MgUser -UserId $UPN -ErrorAction SilentlyContinue
if (-not $User) {
    Write-Host "User $UPN not found!" -ForegroundColor Red
    return
}

Write-Host "Processing transfer for: $($User.DisplayName)" -ForegroundColor Yellow
Write-Host "New Target Department: $NewDepartment" -ForegroundColor Cyan

# 2. Update the user's department property in Entra ID
Update-MgUser -UserId $User.Id -Department $NewDepartment

# 3. Find all department groups this user is currently a member of
$MemberGroups = Get-MgUserMemberOf -UserId $User.Id
$DeptGroups = $MemberGroups | Where-Object { $_.AdditionalProperties.displayName -like "Grp-Dept-*" }

foreach ($Group in $DeptGroups) {
    $GroupName = $Group.AdditionalProperties.displayName
    $ExpectedGroupName = "Grp-Dept-$NewDepartment"

    if ($GroupName -ne $ExpectedGroupName) {
        # Remove from old department group using the corrected Graph cmdlet
        Write-Host "Removing from old group: $GroupName" -ForegroundColor DarkYellow
        Remove-MgGroupMemberDirectoryObjectByRef -GroupId $Group.Id -DirectoryObjectId $User.Id
    }
}

# 4. Ensure user is added to the new department group
$NewGroupName = "Grp-Dept-$NewDepartment"
$TargetGroup = Get-MgGroup -Filter "displayName eq '$NewGroupName'" -ErrorAction SilentlyContinue

if ($TargetGroup) {
    try {
        New-MgGroupMember -GroupId $TargetGroup.Id -DirectoryObjectId $User.Id -ErrorAction Stop
        Write-Host "Successfully added $($User.DisplayName) to new group: $NewGroupName" -ForegroundColor Green
    }
    catch {
        Write-Host "User is already a member of $NewGroupName." -ForegroundColor Gray
    }
}

Write-Host "`nMover Lifecycle Transition Complete!" -ForegroundColor Green