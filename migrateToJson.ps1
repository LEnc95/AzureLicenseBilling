# Migration script to convert CSV data to JSON format
$now = Get-Date
$currentDate = $now.ToString("yyyy-MM-dd")
$currentTime = $now.ToString("HH:mm:ss")

$parentdir = $PSScriptRoot
$csvPath = "$parentdir\dat\licenseData.csv"
$jsonPath = "$parentdir\dat\billingData.json"
$logPath = "$parentdir\dat\log.txt"

Write-Host "Starting migration from CSV to JSON..."

# Initialize array for all data
$allData = @()

# Read existing JSON data if it exists
if (Test-Path $jsonPath) {
    Write-Host "Reading existing JSON data..."
    $existingData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    if ($existingData -is [Array]) {
        $allData = $existingData
    } else {
        $allData = @($existingData)
    }
    Write-Host "Found $($allData.Count) existing JSON entries."
}

# Read and convert CSV data
if (Test-Path $csvPath) {
    Write-Host "Reading CSV data..."
    $csvData = Import-Csv -Path $csvPath
    
    # Convert CSV data to match JSON format
    $convertedData = $csvData | ForEach-Object {
        [PSCustomObject]@{
            SKUPartNumber     = $_.SkuPartNumber
            PrepaidUnits      = [int]$_.TotalLicenses
            ConsumedUnits     = [int]$_.ConsumedLicenses
            AvailableLicenses = [int]$_.AvailableLicenses
            DateRetrieved     = $_.Date
            AppliesTo         = "User"  # Default value since CSV doesn't have this
        }
    }
    
    Write-Host "Converted $($convertedData.Count) CSV entries."
    
    # Add converted data to allData
    $allData += $convertedData
} else {
    Write-Host "No CSV file found at $csvPath"
}

# Sort all data by DateRetrieved
$allData = $allData | Sort-Object -Property DateRetrieved

# Save combined data to JSON
Write-Host "Saving combined data to JSON..."
$allData | ConvertTo-Json -Depth 4 | Set-Content -Path $jsonPath -Encoding utf8

# Log the migration
$logMessage = "[$currentDate $currentTime] Migrated data to JSON format. Total entries: $($allData.Count)"
Add-Content -Path $logPath -Value $logMessage

Write-Host "Migration complete!"
Write-Host "Total entries in JSON: $($allData.Count)"
Write-Host "Data saved to: $jsonPath"
Write-Host "Log entry added to: $logPath" 