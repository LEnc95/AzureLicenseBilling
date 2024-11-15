# Connect to Microsoft Graph API
# Install the Microsoft.Graph module if not already installed
# Install-Module Microsoft.Graph -Scope CurrentUser

# Import the Microsoft.Graph module
Import-Module Microsoft.Graph

# parent directory is the directory where the script is located
$parentdir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# File path to store daily license data
$filePath = "$parentdir\dat\graphLicenseData.csv"

# Get the current date
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Set the required permissions scope
$scopes = @("Directory.Read.All")

# Connect to Microsoft Graph
Connect-MgGraph -Scopes $scopes

#environment variable
$accessToken = (Get-MgContext).AccessToken
$tenantId = (Get-MgContext).tenantId
$clientId = (Get-MgContext).clientId
$clientSecret = (Get-MgContext).clientSecret


# Retrieve license details
$licenses = Get-MgSubscribedSku

foreach ($license in $licenses) {
    $skuPartNumber = $license.SkuPartNumber
    $totalLicenses = $license.PrepaidUnits.Enabled
    $consumedLicenses = $license.ConsumedUnits
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