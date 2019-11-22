param
(
    [Parameter (Mandatory = $false)]
    [object] $WebhookData
)

$licenseVariableName = 'sitecoreLicense'
$fileName = 'license.xml'
$uploadlicense = $true

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


.\loginto-azure.ps1

$licenseContent = Get-AutomationVariable -Name $licenseVariableName

Write-Output "=============="
Write-Output "local file:"
$localFilePath = (New-Item -Path .\license.xml -Value $licenseContent -Force ).FullName
Write-Output $localFilePath
Write-Output "================"


function Get-PublishingProfileCredentials($resourceGroupName, $webAppName){
 
    $resourceType = "Microsoft.Web/sites/config"
    $resourceName = "$webAppName/publishingcredentials"
 
    $publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
 
       return $publishingCredentials
}

function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $webAppName){
 
    $publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $webAppName
 
    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
}


function Upload-FileToWebApp($kuduApiAuthorisationToken, $webAppName, $fileName, $localPath ){
 
    $kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/app_data/$fileName"
     
    $result = Invoke-RestMethod -Uri $kuduApiUrl `
                        -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
                        -Method PUT `
                        -InFile $localPath `
                        -ContentType "multipart/form-data"
}

    

    
    if ($uploadlicense)
        {
          $webapps = (Get-AzureRmWebApp -ResourceGroupName $resourceGroupName)

            foreach ($web in $webapps)
                {
                    Write-Output "copying $fileName license to $($web.name)"

                $kuduauth = Get-KuduApiAuthorisationHeaderValue -resourceGroupName $resourceGroupName -webAppName $($web.name)
                upload-filetowebapp -kuduApiAuthorisationToken $kuduauth -webAppName $($web.name) -fileName $fileName -localPath $localFilePath
                        
                        Write-Output "success!"
                }
        }
         else 
                {
                                    Write-Output "copying  only/single file: $fileName to $web"

                    $kuduauth = Get-KuduApiAuthorisationHeaderValue -resourceGroupName $resourceGroupName -webAppName $($web.name)
                    upload-filetowebapp -kuduApiAuthorisationToken $kuduauth -webAppName $($web.name) -fileName $fileName -localPath $localFilePath
                                
                                            Write-Output "success!"
                }