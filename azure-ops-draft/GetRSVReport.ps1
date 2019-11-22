

$vms = Get-AzVM -ResourceGroupName "global"

foreach ($vm in $vms)
    {


    Get-AzRecoveryServicesBackupStatus -name  $vm.Name -ResourceGroupName $vm.ResourceGroupName -Type AzureVM
    #$bkpVaultName = (((Get-AzRecoveryServicesBackupStatus -name  $vm.Name -ResourceGroupName $vm.ResourceGroupName -Type AzureVM).VaultId) -split '/')[-1]

    }




 Get-AzRecoveryServicesVault -Name "global" | Set-AzRecoveryServicesVaultContext


 $bkp = @()
 foreach ($vm in $vms) 
    {

 $namedContainer = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -Status "Registered" -FriendlyName $vm.name
 $item =   Get-AzRecoveryServicesBackupItem -Container $namedContainer -WorkloadType AzureVM 
 
 $props = @{
 "policyName" = $item.ProtectionPolicyName
 "fabric" = ($item.id -split "/")[-5]
    }
  $obj = New-Object -TypeName psobject -Property $props
  Write-Output $obj
  }




