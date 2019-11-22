param
(
    [Parameter (Mandatory = $false)]
    [object] $WebhookData
)

if ($WebhookData) 
        {
        Write-Output "Processing this runbook with webhook manner"
        }
            else 
                 { 
                    Write-Output "Missing webhook request informations, exiting script"
                    exit;
                 }

$convertParams = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)
[string]$webapprg = $convertParams.resourceGroup | where {$_ -ne $null}

.\loginto-azure.ps1

$webapps = ((Get-AzureRmWebApp -ResourceGroupName $($webapprg)) | where {$_.tags.logicalName -eq 'cd' -or $_.tags.logicalName -eq 'cm' -or $_.tags.logicalName -eq 'single'}).name

foreach ($web in $webapps)
    {
    $webAppConfig = Get-AzureRmResource -ResourceName "$($web)/web" -ResourceType "Microsoft.Web/sites/config" -ApiVersion 2015-08-01 -ResourceGroupName $webapprg
    $currentVnet = $webAppConfig.Properties.VnetName

    if($currentVnet -ne $null -and $currentVnet -ne "")
	{
		Write-Output "$web is Currently connected to VNET $currentVnet"
            continue
	}
        else { 
        		Write-Output "$web is not connected to VNET, connecting to net...."
    $AppServiceName = $web
    $NetworkName = "vnet1"
    $location = "westeurope"
    $netrgname = "vnetngw"
         $props = @{
              "vnetResourceId" = "/subscriptions/92274875-14bd-40b1-8a95-cfc15872fa40/resourceGroups/vnetngw/providers/Microsoft.Network/virtualNetworks/vnet1";
              "certThumbprint"= "544743769C085942912242D643B79A36BBFD9AD3";
              "certBlob"= "MIIDKTCCAhWgAwIBAgIQ253U/Rt5KoVN6Laf0KODcjAJBgUrDgMCHQUAMCYxJDAiBgNVBAMTG1dlYnNpdGVzQ2VydGlmaWNhdGVyd2Utdm5ldDAeFw0xOTAyMTcyMDExNTlaFw0zOTEyMzEyMzU5NTlaMCYxJDAiBgNVBAMTG1dlYnNpdGVzQ2VydGlmaWNhdGVyd2Utdm5ldDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALBVGUMLhqNT95lfaOnCisaRjbjFtaP3ppsV0hvNiqCHjsxmi+NfXNPPY9x6SJEeyR+J0HKlezeps+uNIKBoS1Bay1Dzin1wDGcQxkBsBZrSGq5VGr7cPptKkEXWklBgQm/kpzFtTiBAiye5fQROQ33BmOAgtiIueMIE08bONFdOscop7piBsgm8JhxPOimmbU+nAlYaNYN1xdmETZDavFiCvWyF8Pl1Gp6F33OSbaOyZ9jwzLmQysknpGhfNGKu9eIjbum/I+JlaJKBsgIJRnYQrvHeIerDei10aPVQNlRPpnRqD5z+N/Jq7vFZmpT0m5iVZd2HYOUrvO7wj2rrVSUCAwEAAaNbMFkwVwYDVR0BBFAwToAQTwj5dPErQEeW1AE6IhucHqEoMCYxJDAiBgNVBAMTG1dlYnNpdGVzQ2VydGlmaWNhdGVyd2Utdm5ldIIQ253U/Rt5KoVN6Laf0KODcjAJBgUrDgMCHQUAA4IBAQA/yfGpCxE+hU2D1hn5Pg+Ni3HEUMKXL5cvlESk7bnev3KsH/v/ygQarKsGCiSlbipLln6W4344lFUTfYqb1V5QK45Ydr/66lPHAD+QmeuY24HAVFk3C3MUmuUrtdmkOs0o+ICqwT0uzSEiLqgSrYl4gwszZwp7deiIypuAMCiC7VZMT2B2yDS3szJwZ+Gpgf20DpTMXMOEv00j2wBnOr0jIuEC1HjOuLahZ7XuMofYGOGpxSbUMhssuDHQFc22hjdnM/9vIg8GK6COvQMNwF6ITy68qjCAyjVQ41Kxg6KEFJe1gZCF/Dzosq4pi651iiI8BRcjsSMtorWbTdMJO46e";
              "routes" = $null;
                  }
        New-AzureRMResource -ResourceName "$AppServiceName/$AppServiceName-to-$NetworkName" -Location $location -ResourceGroupName $webapprg -ResourceType 'Microsoft.Web/sites/virtualNetworkConnections' -PropertyObject $props -ApiVersion "2015-08-01" -force 
            }
    }

