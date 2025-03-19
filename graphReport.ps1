# Connect to Microsoft Graph API
# Install the Microsoft.Graph module if not already installed
# Install-Module Microsoft.Graph -Scope CurrentUser

# Use the Microsoft Graph REST API directly without importing the module

# parent directory is the directory where the script is located
$parentdir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# File path to store daily license data
$filePath = "$parentdir\dat\graphLicenseData.csv"

# Get the current date
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Set the required permissions scope
$scopes = @("Directory.Read.All")

# Connect to Microsoft Graph using the REST API
Connect-MgGraph -Scopes $scopes

# Retrieve access token
$accessToken = (Get-MgContext).AccessToken

# Set the URI for retrieving license details
$uri = "https://graph.microsoft.com/v1.0/subscribedSkus"

# Make the REST API request using Invoke-RestMethod
$headers = @{
    'Authorization' = "Bearer $accessToken"
    'Content-Type'  = 'application/json'
}

$licenses = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get

foreach ($license in $licenses.value) {
    $skuPartNumber = $license.skuPartNumber
    $totalLicenses = $license.prepaidUnits.enabled
    $consumedLicenses = $license.consumedUnits
    $availableLicenses = $totalLicenses - $consumedLicenses

    # Prepare data to save to CSV
    $data = [PSCustomObject]@{
        Date             = $currentDate
        SkuPartNumber    = $skuPartNumber
        TotalLicenses    = $totalLicenses
        ConsumedLicenses = $consumedLicenses
        AvailableLicenses = $availableLicenses
    }

    # Append data to CSV file
    if (Test-Path $filePath) {
        $data | Export-Csv -Path $filePath -Append -NoTypeInformation
    } else {
        $data | Export-Csv -Path $filePath -NoTypeInformation
    }
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
