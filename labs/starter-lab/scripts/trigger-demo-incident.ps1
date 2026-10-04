#Requires -Version 7.0
param(
    [Parameter(Mandatory)][uri]$BaseUrl,
    [ValidateRange(6, 20)][int]$Requests = 8,
    [ValidateRange(5, 30)][int]$IntervalSeconds = 10
)

$ErrorActionPreference = 'Stop'
$base = $BaseUrl.AbsoluteUri.TrimEnd('/')
$health = Invoke-WebRequest "$base/health" -TimeoutSec 30 -SkipHttpErrorCheck
if ($health.StatusCode -ne 200) { throw "API is not healthy: HTTP $($health.StatusCode)" }
$body = @{
    userId = "code-incident-demo-$([guid]::NewGuid().ToString('N'))"
    restaurantId = 1
    items = @(@{ id = 1; foodItemId = 1; quantity = 1; specialInstructions = '' })
    deliveryAddress = '1 Demo Way'
    customerPhone = '2025550100'
    paymentMethod = 'credit-card'
    specialInstructions = 'Controlled RCA-only demo; no real payment'
} | ConvertTo-Json -Depth 8

for ($i = 1; $i -le $Requests; $i++) {
    $response = Invoke-WebRequest "$base/api/orders" -Method Post -ContentType 'application/json' `
        -Body $body -TimeoutSec 30 -SkipHttpErrorCheck -MaximumRedirection 0
    if ($response.StatusCode -ne 500) {
        throw "Expected demo checkout HTTP 500, got $($response.StatusCode). Stopping traffic."
    }
    Write-Output "$([DateTime]::UtcNow.ToString('o')) request $i/${Requests}: expected HTTP 500"
    if ($i -lt $Requests) { Start-Sleep -Seconds $IntervalSeconds }
}
Write-Output 'Bounded demo traffic finished. Verify the Azure Monitor alert, SRE incident and GitHub issue separately.'
