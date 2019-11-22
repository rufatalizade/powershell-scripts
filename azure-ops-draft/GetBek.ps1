
## to use  last   "kekUrl" condition  you need proceed script with RM!!!!!!!!!!

Get-AzureRmSubscription | select -Index 3 | Select-AzureRmSubscription

$rgName = "rgName"
$vmname = "vmname1"
$wrappedBek = Get-AzureKeyVaultSecret -VaultName "apac-kv01" | `
where {($_.Tags.MachineName -eq $vmName) -and ($_.Tags.VolumeLetter -eq "E:\") -and ($_.ContentType -eq 'Wrapped BEK')}



  $secretFilePath = "C:\Users\i3001942\Desktop\BC5C04DF-BED5-4A60-8F40-9512367EC834.BEK"


#Login-AzureRmAccount;

#Install Active directory module
Install-Module -Name MSOnline;

#Get current logged in user and active directory tenant details
$ctx = Get-AzureRmContext
$adTenant = $ctx.Tenant.Id;
$currentUser = $ctx.Account.Id

#Get encryption secret url and kek url from VM's encryption settings
#$PLSFCLSAZ01DATA01 = Get-AzureRmVm -ResourceGroupName $rgName -Name $vmName;
$secretUrl = "https://apac-kv1.vault.azure.net/secrets/xxxxxxxxxxxx/xxx" #$vm.EncryptionSettings.DiskEncryptionKey.SecretUrl;
$secretUrl = [System.Uri]$secretUrl;


$kekUrl = "https://apac-kv1.vault.azure.net/keys/GSPKEK/xxxxxxxxxxxxx"


#Retrieve keyvault name, secret name and secret version from secret URL
$keyVaultName = ([System.Uri]$secretUrl).Host.Split('.')[0];
$secretName = ([System.Uri]$secretUrl).Segments[2].TrimEnd('/');
$secretVersion = ([System.Uri]$secretUrl).Segments[2].TrimEnd('/');;

#Set permissions for the current user to unwrap keys and retrieve secrets from KeyVault

#Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName  -PermissionsToKeys decrypt,encrypt,unwrapKey,wrapKey,verify,sign,get,list,update,create,import,delete,backup,restore,recover,purge -PermissionsToSecrets backup,delete,get,list,purge,recover,restore,set -UserPrincipalName $currentUser
Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName  -PermissionsToKeys all -PermissionsToSecrets all -UserPrincipalName $currentUser;

#Retrieve secret from KeyVault secretUrl

$keyVaultSecret = Get-AzureKeyVaultSecret -VaultName $keyVaultName -Name $secretName 
$secretBase64 = $keyVaultSecret.SecretValueText;

#Unwrap secret if the secret is wrapped with KEK
if($kekUrl)
{

    ########################################################################################################################
    # Initialize ADAL libraries and get authentication context required to make REST API called against KeyVault REST APIs. 
    ########################################################################################################################

    # Set well-known client ID for AzurePowerShell
    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2" 
    # Set redirect URI for Azure PowerShell
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    # Set Resource URI to Azure Service Management API
    $resourceAppIdURI = "https://vault.azure.net"
    # Set Authority to Azure AD Tenant
    $authority = "https://login.windows.net/$adTenant"
    # Create Authentication Context tied to Azure AD Tenant
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    # Acquire token
    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
    # Generate auth header 
    $authHeader = $authResult.CreateAuthorizationHeader()
    # Set HTTP request headers to include Authorization header
    $headers = @{'x-ms-version'='2014-08-01';"Authorization" = $authHeader}

    ########################################################################################################################
    # 1. Retrieve the secret from KeyVault
    # 2. If Kek is not NULL, unwrap the secret with Kek by making KeyVault REST API call
    # 3. Convert Base64 string to bytes and write to the BEK file
    ########################################################################################################################

    #Call KeyVault REST API to Unwrap 
    $jsonObject = @"
    {
        "alg": "RSA-OAEP",
        "value" : "$secretBase64"
    }
"@

    $unwrapKeyRequestUrl = $kekUrl+ "/unwrapkey?api-version=2015-06-01";
    $result = Invoke-RestMethod -Method POST -Uri $unwrapKeyRequestUrl -Headers $headers -Body $jsonObject -ContentType "application/json";

    #Convert Base64Url string returned by KeyVault unwrap to Base64 string
    $secretBase64Url = $result.value;
    $secretBase64 = $secretBase64Url.Replace('-', '+');
    $secretBase64 = $secretBase64.Replace('_', '/');
    if($secretBase64.Length %4 -eq 2)
    {
        $secretBase64+= '==';
    }
    elseif($secretBase64.Length %4 -eq 3)
    {
        $secretBase64+= '=';
    }
}

if($secretFilePath)
{
    $bekFileBytes = [System.Convert]::FromBase64String($secretBase64);
    [System.IO.File]::WriteAllBytes($secretFilePath,$bekFileBytes);
}