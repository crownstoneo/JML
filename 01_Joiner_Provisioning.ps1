# ==========================================
# Script: 01_Joiner_Provisioning.ps1
# Purpose: Automated HR CSV User Provisioning Engine
# ==========================================

# 1. Set the file path to your HR input CSV
$CsvPath = "C:\Users\User\Desktop\IAM-lab\Employees_Input.csv"

# Verify the CSV file exists before running
if (-not (Test-Path $CsvPath)) {
    Write-Host "Error: Cannot find $CsvPath. Please check the file path!" -ForegroundColor Red
    return
}

# 2. Import the employee records from the CSV file
$NewEmployees = Import-Csv -Path $CsvPath

# Get your tenant's primary domain name automatically
$TenantDomain = (Get-MgDomain | Where-Object {$_.IsDefault}).Id

Write-Host "Starting User Provisioning Pipeline..." -ForegroundColor Cyan

# 3. Loop through every employee in the CSV
foreach ($Employee in $NewEmployees) {
    
    # Construct the User Principal Name (UPN): firstname.lastname@yourtenant.domain
    $UserPrincipalName = "$($Employee.FirstName).$($Employee.LastName)@$TenantDomain"
    $DisplayName = "$($Employee.FirstName) $($Employee.LastName)"
    
    Write-Host "Processing: $DisplayName ($UserPrincipalName)..." -ForegroundColor Yellow

    # Generate a random temporary password meeting Entra ID complexity requirements
    $TempPassword = "P@ssword$(Get-Random -Minimum 1000 -Maximum 9999)!"

    # Construct the parameters hash table required by Microsoft Graph
    $UserParams = @{
        AccountEnabled    = $true
        DisplayName       = $DisplayName
        GivenName         = $Employee.FirstName
        Surname           = $Employee.LastName
        UserPrincipalName = $UserPrincipalName
        MailNickname      = "$($Employee.FirstName).$($Employee.LastName)"
        Department        = $Employee.Department
        JobTitle          = $Employee.JobTitle
        PasswordProfile   = @{
            ForceChangePasswordNextSignIn = $true
            Password                      = $TempPassword
        }
    }

    try {
        # Create the user in Entra ID using Microsoft Graph API
        $NewUser = New-MgUser @UserParams -ErrorAction Stop
        
        Write-Host "Successfully created user: $($NewUser.DisplayName)" -ForegroundColor Green
        Write-Host "  -> Temp Password: $TempPassword" -ForegroundColor Gray
    }
    catch {
        Write-Host "Failed to create user $UserPrincipalName : $_" -ForegroundColor Red
    }
}

Write-Host "`nJoiner Provisioning Batch Complete!" -ForegroundColor Green