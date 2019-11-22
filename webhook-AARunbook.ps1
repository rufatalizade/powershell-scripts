





Add-CustomDomainToWebApp -partner "int" -env "acc"



#wh-UpdateIPRestrictionList
$params  = @(
            @{ resourceGroup="scxp0-dev"}
            )
$body = ConvertTo-Json -InputObject $params

$uri = "https://s2events.azure-automation.net/webhooks?token={token}"
$header = @{ message="AzureWebhook"}
$response = Invoke-WebRequest -Method Post -Uri $uri -Body $body -Headers $header


#wh-InstallSitecoreLicense
$params  = @(
            @{ resourceGroup="scxp1-int-prod"}
            )
$body = ConvertTo-Json -InputObject $params

$uri = "https://s2events.azure-automation.net/webhooks?token={token}"
$header = @{ message="AzureWebHook"}
$response = Invoke-WebRequest -Method Post -Uri $uri -Body $body -Headers $header


#wh-vNetIntegration
$params  = @(
            @{ resourceGroup="scxp1-prod"}
            )
$body = ConvertTo-Json -InputObject $params

$uri = "https://s2events.azure-automation.net/webhooks?token={tokenid}"
$header = @{ message="AzureWebhook"}
$response = Invoke-WebRequest -Method Post -Uri $uri -Body $body -Headers $header


#wh-customDomain
$params  = @(
            @{ webappName="scxp0-test-single"}
            @{ customDomainToSet="test-customDomain.Net"}
            @{ certVaultName="pfx-base64-v2"}
            @{ certPassVaultName="pfx-base64-psw-v2"}
            )
$body = ConvertTo-Json -InputObject $params

$uri = "https://s2events.azure-automation.net/webhooks?token={tokenid}"
$header = @{ message="AzureWebhook"}
$response = Invoke-WebRequest -Method Post -Uri $uri -Body $body -Headers $header


