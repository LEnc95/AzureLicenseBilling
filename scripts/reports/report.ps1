# Connect to Azure AD
#Connect-AzureAD

# Get the project root directory
$rootDir = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$filePath = Join-Path $rootDir 'dat\licenseData.csv'

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
