$bytes = New-Object byte[] 32
$generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$generator.GetBytes($bytes)
$key = [Convert]::ToBase64String($bytes).Replace("+", "-").Replace("/", "_")
$generator.Dispose()

Write-Host "Copy this value into the GitHub Secret STATE_ENCRYPTION_KEY:"
Write-Host $key
Write-Host "Do not put this value in a file, Variable, screenshot, workflow input, or chat."
