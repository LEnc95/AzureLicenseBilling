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
        # (Placeholder) Add your OAuth token retrieval logic here if needed.
        # For now, we'll assume Windows auth or integrated auth is enough.
        Write-Verbose "OAuth retrieval not implemented in this example."
    }
    else {
        $BaseURL += '/winauthwebservices/api/v1/secrets'
        $Arglist['UseDefaultCredentials'] = $true
    }

    $Arglist['Uri'] = "$BaseURL/$SecretID"
    Write-Verbose "Retrieving secret details from: $($Arglist['Uri'])"
    $SecretDetails = Invoke-RestMethod @Arglist
    return $SecretDetails
}

# ---------------------------------------------------------
# 2) GET SERVICE PRINCIPAL SECRETS FROM SECRET SERVER
# ---------------------------------------------------------
# Adjust SecretID to your actual ID that contains the clientId, clientSecret, tenantId
$SecretID = 42813

Write-Host "Retrieving credentials from Secret Server..."
$secretDetails = Get-SecretServerSecretDetails -SecretID $SecretID -TLS12

# We expect $secretDetails.items to contain something like:
#   slug: "clientId"     - Value: "YOUR-CLIENT-ID"
#   slug: "clientSecret" - Value: "YOUR-CLIENT-SECRET"
#   slug: "tenantId"     - Value: "YOUR-TENANT-ID"
# Adjust the slugs to match how your secrets are actually named.
$clientId     = ($secretDetails.items | Where-Object { $_.slug -eq "clientId" }).itemValue
$clientSecret = ($secretDetails.items | Where-Object { $_.slug -eq "clientSecret" }).itemValue
$tenantId     = ($secretDetails.items | Where-Object { $_.slug -eq "tenantId" }).itemValue

Write-Host "Client ID:    $clientId"
Write-Host "Tenant ID:    $tenantId"
Write-Host "ClientSecret: retrieved (not displaying)"

# ---------------------------------------------------------
# 3) GET AN ACCESS TOKEN USING CLIENT CREDENTIALS
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
}
catch {
    Write-Error "Failed to retrieve access token: $($_.Exception.Message)"
    return
}