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
[string]$resourceGroupName = $convertParams.resourceGroup | where {$_ -ne $null}
[string]$appGwResourceName = $convertParams.appGwResourceName | where {$_ -ne $null}
Write-Output "=====resource group name====="
Write-Output $resourceGroupName
Write-Output "=====appGwResourceName====="
Write-Output $appGwResourceName
Write-Output "-----------------------------"


.\loginto-azure.ps1


$AllowedIP = Get-AutomationVariable -Name 'AllowedIPList'
$AllowedIP = $AllowedIP  -split "," |%{$($_.TrimStart()).TrimEnd()}

$startPriorityNumber = 120


function Add-AzureIpRestriction
{
    [CmdletBinding()]
    Param
    (
        # Name of the resource group that contains the App Service.
        [Parameter(Mandatory=$true, Position=0)]
        $ResourceGroupName, 
 
        # rule to add.
        [Parameter(Mandatory=$false, Position=1)]
        [PSCustomObject]$rule,

        # Name of your Web or API App.
        [string]$AppServiceName
 

    )


 
    $ApiVersions = Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Web |
        Select-Object -ExpandProperty ResourceTypes |
        Where-Object ResourceTypeName -eq 'sites' |
        Select-Object -ExpandProperty ApiVersions
 
    $LatestApiVersion = $ApiVersions[0]





 if (!$AppServiceName) 
    {
        $webapps = ((Get-AzureRmWebApp -ResourceGroupName "$ResourceGroupName") | where {$_.name -notmatch '-cd' -and $_.tags.logicalName -ne 'cd'}).sitename

        foreach ($web in $webapps) 
            {
                    Write-Host "setting IPRestriction for web application: $web...."
                $WebAppConfig = Get-AzureRmResource -ResourceType 'Microsoft.Web/sites/config' -ResourceName $web -ResourceGroupName $ResourceGroupName -ApiVersion $LatestApiVersion

                 if ($WebAppConfig.Properties.ipSecurityRestrictions.priority) { $startPriorityNumber =  (($w.Properties.ipSecurityRestrictions.priority)[-1]+1)}
                                else { 
                                    $startPriorityNumber = 120
                                        }



                       foreach ($ip in $AllowedIP)         
                                  {
                                  Write-Host "Adding $ip to IPRestriction list.." 

                                            if ($WebAppConfig.Properties.ipSecurityRestrictions | where {$_.ipAddress -eq "$ip"})
                                                    {
                                                            Write-Host "Ip address $ip  already exist in restriction list"
                                                            continue
                                                  } 
                                                        else { 
                                                                $startPriorityNumber
                                                                $priority = $startPriorityNumber++
                                                                $rule = [PSCustomObject]@{
                                                                                        ipAddress = "$ip"
                                                                                        action = "Allow" 
                                                                                        priority = $priority 
                                                                                        name = "Allow $ip"
                                                                                        description = "Automatically added ip restriction"
                                                                                        }


                                                                        Write-Host "IP address object details:" 
                                                                        Write-Host "$rule"
                                                                        $WebAppConfig.Properties.ipSecurityRestrictions =  $WebAppConfig.Properties.ipSecurityRestrictions + @($rule)
                                                                            rv rule           
                                                                            Start-Sleep -Milliseconds 100
                                                                } 
                                  } 

              $WebAppConfig | Set-AzureRmResource  -ApiVersion $LatestApiVersion -Force
          }
    }


 if ($AppServiceName) 
    {

    Write-Host "setting IPRestriction for web application: $AppServiceName...."

        $WebAppConfig = Get-AzureRmResource -ResourceType 'Microsoft.Web/sites/config' -ResourceName $AppServiceName -ResourceGroupName $ResourceGroupName -ApiVersion $LatestApiVersion
        if ($WebAppConfig.Properties.ipSecurityRestrictions.priority) { $startPriorityNumber =  (($w.Properties.ipSecurityRestrictions.priority)[-1]+1)}
                                  else { 
                                            $startPriorityNumber = 120
                                        }

       foreach ($ip in $AllowedIP)         
                  {
                  Write-Host "Adding $ip to IPRestriction list.." 

                            if ($WebAppConfig.Properties.ipSecurityRestrictions | where {$_.ipAddress -eq "$ip"})
                                    {
                                            Write-Host "Ip address $ip  already exist in restriction list"
                                            continue
                                  } 
                                    else { 
                                        $startPriorityNumber
                                        $priority = $startPriorityNumber++
                                        $rule = [PSCustomObject]@{
                                                                ipAddress = "$ip"
                                                                action = "Allow" 
                                                                priority = $priority 
                                                                name = "Allow $ip"
                                                                description = "Automatically added ip restriction"
                                                                }
                                Write-Host "IP address object details:" 
                                Write-Host "$rule"
                                                 $WebAppConfig.Properties.ipSecurityRestrictions = $WebAppConfig.Properties.ipSecurityRestrictions + @($rule)
                                                                     rv rule           
                                                                         Start-Sleep -Milliseconds 100
                                            } 
                  } 

            $WebAppConfig | Set-AzureRmResource  -ApiVersion $LatestApiVersion -Force
    }



 if ($RemoveIP -and $AppServiceName) 
    {

    $WebAppConfig = Get-AzureRmResource -ResourceType 'Microsoft.Web/sites/config' -ResourceName $AppServiceName -ResourceGroupName $ResourceGroupName -ApiVersion $LatestApiVersion

        if ($WebAppConfig.Properties.ipSecurityRestrictions | where {$_.ipAddress -eq $RemoveIP})
            {
                    Write-Host "$ip has found in list, excluding from the list..." 

       

                                $exclude =  $WebAppConfig.Properties.ipSecurityRestrictions | where {$_.ipAddress -ne $RemoveIP}

                                $WebAppConfig.Properties.ipSecurityRestrictions = $null 

                                $WebAppConfig.Properties.ipSecurityRestrictions = $exclude

            }
            else { 

                    Write-Host "IP address was not found in the list"
                 }

    }

}


function Update-AzureIPRestriction
{
    [CmdletBinding()]
    Param
    (
        # Name of the resource group that contains the App Service.
        [Parameter(Mandatory=$true, Position=0)]
        $ResourceGroupName,
        [string]$appGwResourceName  #for cd
    )

 
$AllowedIP = Get-AutomationVariable -Name 'AllowedIPList'
$AllowedIP = $AllowedIP  -split "," |%{$($_.TrimStart()).TrimEnd()}
   
        $ApiVersions = Get-AzureRmResourceProvider -ProviderNamespace Microsoft.Web |
        Select-Object -ExpandProperty ResourceTypes |
        Where-Object ResourceTypeName -eq 'sites' |
        Select-Object -ExpandProperty ApiVersions
 
    $LatestApiVersion = $ApiVersions[0]
    $webapps = (Get-AzureRmWebApp -ResourceGroupName $($ResourceGroupName)) | where {$_.name -notmatch '-cd' -and $_.tags.logicalName -ne 'cd'}
    $outboundIpsFromAllWebApps  = $webapps.outboundIpAddresses
    $outboundIps =  (($outboundIpsFromAllWebApps -join ",") -split "," | select -unique) | % { $_ + '/' + '32'}
    $AllowedIP += $outboundIps


        $websitescnfg = $webapps | foreach { Get-AzureRmResource -ResourceType 'Microsoft.Web/sites/config' -ResourceName $($_.name)  -ResourceGroupName $ResourceGroupName -ApiVersion $LatestApiVersion}
        $startPriorityNumber = 120 

            $tbl = @()
            foreach ($ip in $AllowedIP)
                    {
                        $priority = $startPriorityNumber++
                        $rule = [PSCustomObject]@{
                                                ipAddress = "$ip"
                                                action = "Allow" 
                                                priority = $priority 
                                                name = "Allow $ip"
                                                description = "Automatically added ip restriction"
                                                }
                                $tbl += $rule
                    }

            foreach ($app in $websitescnfg)
                    {
                    $($app.Properties).ipSecurityRestrictions = $null 
                    $($app.Properties).ipSecurityRestrictions = $tbl
                    Set-AzureRmResource -ResourceId $($app.ResourceId) -Properties $($app.Properties) -ApiVersion $LatestApiVersion -Force
                    }

                    $cd = (Get-AzureRmWebApp -ResourceGroupName $($ResourceGroupName)) | where {$_.name -match '-cd' -and $_.tags.logicalName -eq 'cd'}
                        if ($cd)
                            {
                                $publicIpId = (((Get-AzureRmApplicationGateway -ResourceGroupName $appGwResourceName).FrontendIpConfigurationsText | ConvertFrom-Json).publicIPAddress).id
                                $publicIp = (Get-AzureRmResource -ResourceId $publicIpId).Properties.ipaddress
                                $cdwebsitescnfg = $cd | foreach { Get-AzureRmResource -ResourceType 'Microsoft.Web/sites/config' -ResourceName $($_.name) -ResourceGroupName $ResourceGroupName -ApiVersion $LatestApiVersion}

                                Write-Output "Your app gateway public ip is: $($publicIp)"
                                                        $tbl  = @()
                                                        $tbl2 = [PSCustomObject]@{
                                                                            ipAddress = $($publicIp) + '/32'
                                                                            action = "Allow" 
                                                                            priority = 500
                                                                            name = "Allow AppGwIP"
                                                                            description = "Allow traffic only from AppGw IP"
                                                                            }
                                                        $tbl += $tbl2

                                        foreach ($app in $cdwebsitescnfg)
                                                {
                                                $($app.Properties).ipSecurityRestrictions = $null 
                                                $($app.Properties).ipSecurityRestrictions = $tbl
                                                Set-AzureRmResource -ResourceId $($app.ResourceId) -Properties $($app.Properties) -ApiVersion $LatestApiVersion -Force
                                                }
                            }

}

Update-AzureIPRestriction -ResourceGroupName $resourceGroupName -appGwResourceName  $appGwResourceName