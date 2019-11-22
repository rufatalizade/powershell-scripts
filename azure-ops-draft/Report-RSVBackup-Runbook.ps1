$connection = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzureRmAccount -ServicePrincipal -Tenant $connection.TenantID -ApplicationId $connection.ApplicationID -CertificateThumbprint $connection.CertificateThumbprint

$subscription = Get-AutomationVariable -Name 'Production SubscriptionID'
Select-AzureRmSubscription $subscription

# Get SMTP configuration details
$emailSMTPServer = "smtp.office365.com"
$credObject = Get-AutomationPSCredential -Name "Office365credentials"
$emailFromAddress = $credObject.UserName
$emailToAddress = "myemail@domain.net"
$emailSubject = "Azure Disaster Recovery Service report"

# Get replicated items and format
$replicatedItems = Get-AzureRmResource -ResourceGroupName "globalRgName" `
                        -ResourceType Microsoft.RecoveryServices/vaults/replicationProtectedItems `
                        -ResourceName "rsvResource" `
                        -ApiVersion 2016-08-10 `
                        | Select -expandproperty Properties `
                        | Select-Object `
                            @{Name="Name"; Expression={$_.FriendlyName}}, `
                            @{Name="Protection State"; Expression={$_.protectionState}}, `
                            @{Name="Replication Health"; Expression={$_.replicationHealth}}, `
                            @{Name="Error"; Expression={ $_.replicationHealthErrors | Select-Object -ExpandProperty ErrorMessage }}, `
                            @{Name="Data Change Rate (MB)"; Expression={ [math]::round(
                                ($_.ProviderSpecificDetails | Select-Object -ExpandProperty compressedDataRateInMb),2
                            )}}

# Set header CSS
$header = @"
<style type='text/css'> 
    body { 
        display: block;
        margin-left: auto;
        margin-right: auto;
        background-color: whitesmoke; 
        font-family:Calibri; 
        color:black; 
    } 
    table { 
        display: block;
        margin-left: auto;
        margin-right: auto;
        align: center;
    }

    table.center {
        margin-left:auto; 
        margin-right:auto;
    }

    td {
        padding:0px 20px;
        text-align: left;
        font-size: 17px;
    }

    tr {
        background-color: white; 
    }

    th { 
        background-color: #00a1f1; 
        font-weight: 700;
        padding:0px 20px;
		height: 40px;
        font-size: 20px;
		text-align: left;
    }  

    .content { 
        background-color: white; 
        padding: 10px 20px;
		margin-left: auto;
        margin-right: auto;
		width: 70%;
    } 

    H1 { 
        text-align:center;
    } 
    H2 { 
        text-align:center;
    } 
</style> 
"@

# Create header of mail
$intro = "<H1>VMware to Azure Site Recovery Report</H1>"

# Create table of total amount of items and total data change rate
$totals = $replicatedItems.'Data Change Rate (MB)' | Measure-Object -Sum | Select @{Name="Total Items"; Expression={ $_.Count}}, @{Name="Total Data Change Rate (MB)"; Expression={ $_.sum}} | ConvertTo-HTML -Fragment -PreContent "<H2>Totals</H2>"

# Create table of top 5 cata change rate items
$topTable = $replicatedItems | Sort-Object -property compressedDataRateInMb -Descending | Select -first 5 | ConvertTo-HTML -Fragment -PreContent "</br><H2>Top 5 - Daily Data Change Rate</H2>"

# Create table of all items
$allItemsTable = $replicatedItems | ConvertTo-HTML -Fragment -PreContent "</br><H2>All Items</H2>"

$body = ConvertTo-HTML -Head $header -body "<table><tr><td> $intro $totals $topTable $allItemsTable </td></tr></table>" | Out-String

Send-MailMessage -Credential $credObject -From $emailFromAddress -To $emailToAddress -Subject $emailSubject -Body $body -SmtpServer $emailSMTPServer -Port 587 -UseSSL -BodyAsHtml
