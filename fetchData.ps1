# Get current date and time
$now = Get-Date
$currentDate = $now.ToString("yyyy-MM-dd")
$currentTime = $now.ToString("HH:mm:ss")

function Get-SecretServerSecretDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$SecretID,
        [Parameter(Mandatory=$false)]
        [string]$SecretServerName = 'creds.gianteagle.com',
        [switch]$TLS12,
        [switch]$oAuth
    )

    if ($TLS12) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    $BaseURL = "https://$SecretServerName/SecretServer"
    $Arglist = @{}

    if ($oAuth) {
        Write-Verbose "OAuth retrieval not implemented in this example."
    } else {
        $BaseURL += '/winauthwebservices/api/v1/secrets'
        $Arglist['UseDefaultCredentials'] = $true
    }

    $Arglist['Uri'] = "$BaseURL/$SecretID"
    Write-Verbose "Retrieving secret details from: $($Arglist['Uri'])"
    return Invoke-RestMethod @Arglist
}

# ---------------------------------------------------------
# 1) GET SERVICE PRINCIPAL SECRETS FROM SECRET SERVER
# ---------------------------------------------------------
$SecretID = 42813
Write-Host "Retrieving credentials from Secret Server..."
$secretDetails = Get-SecretServerSecretDetails -SecretID $SecretID -TLS12

$clientId     = ($secretDetails.items | Where-Object { $_.slug -eq "clientId" }).itemValue
$clientSecret = ($secretDetails.items | Where-Object { $_.slug -eq "clientSecret" }).itemValue
$tenantId     = ($secretDetails.items | Where-Object { $_.slug -eq "tenantId" }).itemValue

if (-not $clientId -or -not $clientSecret -or -not $tenantId) {
    Write-Error "Missing one or more required secret values (clientId, clientSecret, tenantId)."
    return
}

Write-Host "Client ID:    $clientId"
Write-Host "Tenant ID:    $tenantId"
Write-Host "ClientSecret: retrieved (not displaying)"

# ---------------------------------------------------------
# 2) GET ACCESS TOKEN USING CLIENT CREDENTIALS
# ---------------------------------------------------------
Write-Host "Obtaining Azure AD token via client credentials..."
$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$body = @{
    client_id     = $clientId
    client_secret = $clientSecret
    scope         = "https://graph.microsoft.com/.default"
    grant_type    = "client_credentials"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri $tokenEndpoint -Method POST -Body $body -ErrorAction Stop
    $accessToken   = $tokenResponse.access_token
    Write-Host "Token acquired successfully."
} catch {
    $errorMessage = "[$currentDate $currentTime] ERROR: Failed to retrieve access token: $($_.Exception.Message)"
    Write-Error $errorMessage
    Add-Content -Path "$PSScriptRoot\dat\log.txt" -Value $errorMessage
    return
}

# ---------------------------------------------------------
# 3) QUERY GRAPH API FOR LICENSE DATA
# ---------------------------------------------------------
$graphUrl = "https://graph.microsoft.com/v1.0/subscribedSkus"
$graphHeaders = @{
    Authorization = "Bearer $accessToken"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri $graphUrl -Method GET -Headers $graphHeaders -ErrorAction Stop
    Write-Host "Retrieved billing data successfully."
} catch {
    $errorMessage = "[$currentDate $currentTime] ERROR: Failed to retrieve billing data: $($_.Exception.Message)"
    Write-Error $errorMessage
    Add-Content -Path "$PSScriptRoot\dat\log.txt" -Value $errorMessage
    return
}

# ---------------------------------------------------------
# 4) PROCESS AND STORE LICENSE DATA
# ---------------------------------------------------------
$billingData = $response.value | ForEach-Object {
    [PSCustomObject]@{
        SKUId             = $_.skuId
        SKUPartNumber     = $_.skuPartNumber
        PrepaidUnits      = $_.prepaidUnits.enabled
        ConsumedUnits     = $_.consumedUnits
        AvailableLicenses = $_.prepaidUnits.enabled - $_.consumedUnits
        DateRetrieved     = $now.ToString("yyyy-MM-ddTHH:mm:ss")
        AppliesTo         = $_.appliesTo
    }
}

$billingData | Format-Table -AutoSize

$parentdir = $PSScriptRoot
$csvPath = "$parentdir\dat\billingData.csv"
$jsonPath = "$parentdir\dat\billingData.json"
$logPath = "$parentdir\dat\log.txt"

$logMessage = "[$currentDate $currentTime] Billing data retrieved and saved."

# Save to CSV
if (Test-Path $csvPath) {
    $billingData | Export-Csv -Path $csvPath -Append -NoTypeInformation
    $logMessage += " Appended to billingData.csv."
} else {
    $billingData | Export-Csv -Path $csvPath -NoTypeInformation
    $logMessage += " Created billingData.csv."
}

# Save to JSON with append functionality
$jsonData = @()
if (Test-Path $jsonPath) {
    $existingData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    if ($existingData -is [Array]) {
        $jsonData = $existingData
    } else {
        $jsonData = @($existingData)
    }
}
$jsonData += $billingData
$jsonData | ConvertTo-Json -Depth 4 | Set-Content -Path $jsonPath -Encoding utf8
$logMessage += " Updated billingData.json."

# Write to log
Add-Content -Path $logPath -Value $logMessage
