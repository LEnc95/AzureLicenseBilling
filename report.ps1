# Connect to Azure AD
#Connect-AzureAD

#parent directory is the directory where the script is located
$parentdir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# File path to store daily license data
$filePath = "$parentdir\dat\licenseData.csv"

# Get the current date
$currentDate = Get-Date -Format "yyyy-MM-dd"

# Retrieve license details
$licenses = Get-AzureADSubscribedSku

foreach ($license in $licenses) {
    $skuPartNumber = $license.SkuPartNumber
    $totalLicenses = $license.PrepaidUnits.Enabled
    $consumedLicenses = $license.ConsumedUnits
    $availableLicenses = $totalLicenses - $consumedLicenses

    # Prepare data to save to CSV
    $data = [PSCustomObject]@{
        Date            = $currentDate
        SkuPartNumber   = $skuPartNumber
        TotalLicenses   = $totalLicenses
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
