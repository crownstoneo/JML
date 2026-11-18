# ==========================================
# Script: 01b_Assign_Department_Groups.ps1
# Purpose: Auto-assign users to Department Security Groups
# ==========================================

$CsvPath = ".\Employees_Input.csv"
$Employees = Import-Csv -Path $CsvPath
$TenantDomain = (Get-MgDomain | Where-Object {$_.IsDefault}).Id

Write-Host "Starting Group Assignment Engine..." -ForegroundColor Cyan

foreach ($Emp in $Employees) {
    $UPN = "$($Emp.FirstName).$($Emp.LastName)@$TenantDomain"
    $Dept = $Emp.Department
    $GroupName = "Grp-Dept-$Dept"

    # 1. Fetch user account from Entra ID
    $User = Get-MgUser -UserId $UPN -ErrorAction SilentlyContinue
    if (-not $User) {
        Write-Host "User $UPN not found in Entra ID. Skipping..." -ForegroundColor Red
        continue
    }

    # 2. Check if the Department Security Group exists; create it if missing
    $Group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction SilentlyContinue
    if (-not $Group) {
        Write-Host "Group '$GroupName' missing. Creating..." -ForegroundColor Yellow
        $Group = New-MgGroup -DisplayName $GroupName `
                             -MailEnabled:$false `
                             -MailNickname $GroupName `
                             -SecurityEnabled:$true `
                             -GroupTypes @()
    }

    # 3. Add user to the department security group
    try {
        New-MgGroupMember -GroupId $Group.Id -DirectoryObjectId $User.Id -ErrorAction Stop
        Write-Host "Assigned $($User.DisplayName) to group: $GroupName" -ForegroundColor Green
    }
    catch {
        Write-Host "User $($User.DisplayName) is already in $GroupName or error occurred." -ForegroundColor Gray
    }
}

Write-Host "`nGroup RBAC Assignment Complete!" -ForegroundColor Green