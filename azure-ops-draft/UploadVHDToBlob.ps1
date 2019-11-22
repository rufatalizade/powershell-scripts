$resourceGroupName = "global"

$urlOfUploadedVhd = "https://stacc.blob.core.windows.net/vhds/vm.vhd?st={sasToken}"
Add-AzVhd -ResourceGroupName $resourceGroupName `
   -Destination $urlOfUploadedVhd `
   -LocalFilePath "C:\AzureVMs\abcd.vhd"


$sourceUri = 'https://stacc.blob.core.windows.net/vhds/vmdisk.vhd'
$osDiskName = 'vmdisk-OS02'
$osDisk = New-AzDisk -DiskName $osDiskName -Disk `
    (New-AzDiskConfig -AccountType  'Premium_LRS' `
	-Location "westeurope" -CreateOption Import -DiskSizeGB 64 `
    -SourceUri $sourceUri) `
    -ResourceGroupName "global"


$os02 = Get-AzDisk -ResourceGroupName $resourceGroupName -DiskName "vmdisk-OS02"

######################
get-azdi

$diskconfig = -AccountType  'Premium_LRS' -Location "westeurope" -CreateOption Import -SourceUri $sourceUri -EncryptionSettingsEnabled $true;

$diskConfig.EncryptionSettingsCollection = New-Object Microsoft.Azure.Management.Compute.Models.EncryptionSettingsCollection

$encryptionSettingsElement1 = New-Object Microsoft.Azure.Management.Compute.Models.EncryptionSettingsElement
$encryptionSettingsElement1.DiskEncryptionKey = New-Object Microsoft.Azure.Management.Compute.Models.KeyVaultAndSecretReference
$encryptionSettingsElement1.DiskEncryptionKey.SourceVault = New-Object Microsoft.Azure.Management.Compute.Models.SourceVault
$encryptionSettingsElement1.DiskEncryptionKey.SourceVault.Id = $disk_encryption_key_id_1
$encryptionSettingsElement1.DiskEncryptionKey.SecretUrl = $disk_encryption_secret_url_1
$encryptionSettingsElement1.KeyEncryptionKey = New-Object Microsoft.Azure.Management.Compute.Models.KeyVaultAndKeyReference
$encryptionSettingsElement1.KeyEncryptionKey.SourceVault = New-Object Microsoft.Azure.Management.Compute.Models.SourceVault
$encryptionSettingsElement1.KeyEncryptionKey.SourceVault.Id = $key_encryption_key_id_1
$encryptionSettingsElement1.KeyEncryptionKey.KeyUrl = $key_encryption_key_url_1

$diskConfig.EncryptionSettingsCollection.EncryptionSettings += $encryptionSettingsElement1

New-AzDisk -ResourceGroupName 'ResourceGroup01' -DiskName 'Disk01' -Disk $diskconfig;