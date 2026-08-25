$ErrorActionPreference = "Stop"

$defaultRedirectUri = "https://example.com/"
$scope = "snapchat-marketing-api"

function Read-Required([string]$Prompt) {
    do {
        $value = Read-Host $Prompt
    } while ([string]::IsNullOrWhiteSpace($value))
    return $value.Trim()
}

function Get-QueryValue([string]$Url, [string]$Name) {
    $uri = [Uri]$Url
    foreach ($part in $uri.Query.TrimStart("?").Split("&")) {
        if ([string]::IsNullOrWhiteSpace($part)) { continue }
        $pair = $part.Split("=", 2)
        if ($pair.Count -eq 2 -and $pair[0] -eq $Name) {
            return [Uri]::UnescapeDataString($pair[1].Replace("+", " "))
        }
    }
    return $null
}

Write-Host "Snapchat OAuth helper" -ForegroundColor Cyan
Write-Host "This helper does not save your client secret or tokens to a file."
Write-Host ""
$redirectInput = Read-Host "Redirect URI [$defaultRedirectUri]"
$redirectUri = if ([string]::IsNullOrWhiteSpace($redirectInput)) {
    $defaultRedirectUri
} else {
    $redirectInput.Trim()
}
Write-Host "The OAuth app Redirect URI must be exactly: $redirectUri" -ForegroundColor Yellow
Write-Host ""

$clientId = Read-Required "Paste SNAP_CLIENT_ID"
$secureSecret = Read-Host "Paste SNAP_CLIENT_SECRET" -AsSecureString
$clientSecret = [System.Net.NetworkCredential]::new("", $secureSecret).Password
if ([string]::IsNullOrWhiteSpace($clientSecret)) {
    throw "Client secret cannot be empty."
}

$state = [Guid]::NewGuid().ToString("N")
$authUrl = "https://accounts.snapchat.com/login/oauth2/authorize" +
    "?client_id=$([Uri]::EscapeDataString($clientId))" +
    "&redirect_uri=$([Uri]::EscapeDataString($redirectUri))" +
    "&response_type=code" +
    "&scope=$([Uri]::EscapeDataString($scope))" +
    "&state=$state"

Write-Host ""
Write-Host "A Snapchat authorization page will open." -ForegroundColor Cyan
Write-Host "Approve access, then copy the COMPLETE redirected URL from the browser address bar."
Write-Host "The URL must still contain both code= and state=."
Start-Process $authUrl

$returnedUrl = Read-Required "Paste the complete redirected URL"
$returnedState = Get-QueryValue $returnedUrl "state"
$code = Get-QueryValue $returnedUrl "code"

if ($returnedState -ne $state) {
    throw "OAuth state did not match. Stop and run this helper again."
}
if ([string]::IsNullOrWhiteSpace($code)) {
    throw "No OAuth code was found in the pasted URL."
}

$tokenRequest = @{
    Method = "Post"
    Uri = "https://accounts.snapchat.com/login/oauth2/access_token"
    ContentType = "application/x-www-form-urlencoded"
    Body = @{
        grant_type = "authorization_code"
        client_id = $clientId
        client_secret = $clientSecret
        code = $code
        redirect_uri = $redirectUri
    }
}
$tokenResponse = Invoke-RestMethod @tokenRequest

if ([string]::IsNullOrWhiteSpace($tokenResponse.refresh_token)) {
    throw "Snapchat did not return a refresh token."
}

Write-Host ""
Write-Host "SUCCESS - copy this value now into the GitHub secret SNAP_REFRESH_TOKEN:" -ForegroundColor Green
Write-Host $tokenResponse.refresh_token -ForegroundColor Yellow
Write-Host ""

$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)" }
$organizationRequest = @{
    Method = "Get"
    Uri = "https://adsapi.snapchat.com/v1/me/organizations?with_ad_accounts=true"
    Headers = $headers
}
$organizations = Invoke-RestMethod @organizationRequest

Write-Host "Organizations and ad accounts visible to this Snapchat user:" -ForegroundColor Cyan
$organizations.organizations | ForEach-Object {
    $organization = if ($_.organization) { $_.organization } else { $_ }
    Write-Host "Organization: $($organization.name) | ID: $($organization.id)"
    $organization.ad_accounts | ForEach-Object {
        $account = if ($_.ad_account) { $_.ad_account } else { $_ }
        Write-Host "  Ad Account: $($account.name) | ID: $($account.id)"
    }
}

Write-Host ""
$adAccountId = Read-Required "Paste the exact Ad Account ID to list its campaigns"
$campaignUri = "https://adsapi.snapchat.com/v1/adaccounts/{0}/campaigns?limit=1000&sort=updated_at-desc" -f $adAccountId
$campaignRequest = @{
    Method = "Get"
    Uri = $campaignUri
    Headers = $headers
}
$campaignResponse = Invoke-RestMethod @campaignRequest

Write-Host "Campaigns:" -ForegroundColor Cyan
$campaignResponse.campaigns | ForEach-Object {
    $campaign = if ($_.campaign) { $_.campaign } else { $_ }
    Write-Host "  $($campaign.name) | $($campaign.status) | ID: $($campaign.id)"
}

Write-Host ""
$campaignId = Read-Required "Paste the exact Campaign ID to list its ad squads"
$squadUri = "https://adsapi.snapchat.com/v1/campaigns/{0}/adsquads?limit=1000&sort=updated_at-desc" -f $campaignId
$squadRequest = @{
    Method = "Get"
    Uri = $squadUri
    Headers = $headers
}
$squadResponse = Invoke-RestMethod @squadRequest

Write-Host "Ad Squads:" -ForegroundColor Cyan
$squadResponse.adsquads | ForEach-Object {
    $squad = if ($_.adsquad) { $_.adsquad } else { $_ }
    Write-Host "  $($squad.name) | $($squad.status) | ID: $($squad.id)"
}

Write-Host ""
Write-Host "Store the exact Ad Account and Ad Squad IDs only in GitHub Secrets." -ForegroundColor Green
Write-Host "Close this window after you have saved the refresh token securely."
