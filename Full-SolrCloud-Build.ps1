
$zk = "https://stastoraccount.blob.core.windows.net/public/commoncontainer-dev/zookeeper-3.4.10.zip"

$filename     = Split-Path $zk -Leaf
$nssmRoot     = 'C:\nssm-2.24'
$solrRoot     = 'c:\solr'
$solrCertParh = 'etc/solr-ssl.keystore.jks'
$solrCertPass = 'Selfsolr19'
$solrSvcName  = 'solr'
$solrPort     = '8984'


if($solrHost -ne "localhost")
{
    $hostFileName = "c:\\windows\system32\drivers\etc\hosts"
    $hostFile = [System.Io.File]::ReadAllText($hostFileName)
    if(!($hostFile -like "*$solrHost*"))
    {
        Write-Host "Updating host file"
        "`r`n127.0.0.1`t$solrHost" | Add-Content $hostFileName
    }
}


function Set-SolrSslConfig ($solrRoot,$solrCertParh,$solrCertPass) 
    {
        $cfg = Get-Content "$solrRoot\bin\solr.in.cmd"
        Rename-Item "$solrRoot\bin\solr.in.cmd" "$solrRoot\bin\solr.in.cmd.old"
        $newCfg = $cfg    | % { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$solrCertParh" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=$solrCertPass" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$solrCertParh" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=$solrCertPass" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_TYPE=JKS", "set SOLR_SSL_KEY_STORE_TYPE=JKS" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_TYPE=JKS", "set SOLR_SSL_TRUST_STORE_TYPE=JKS" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_NEED_CLIENT_AUTH=false", "set SOLR_SSL_NEED_CLIENT_AUTH=false" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_WANT_CLIENT_AUTH=false", "set SOLR_SSL_WANT_CLIENT_AUTH=false" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=localhost" }
        $newCfg | Set-Content "$solrRoot\bin\solr.in.cmd"
   }

Set-SolrSslConfig -solrRoot $solrRoot -solrCertParh $solrCertParh -solrCertPass $solrCertPass 




$svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
if(!($svc))
{
    Write-Host "Installing Solr service"
    &"$nssmRoot\win64\nssm.exe" install "$solrSvcName" "$solrRoot\bin\solr.cmd" "-f" "-p $solrPort"
    $svc = Get-Service "$solrSvcName" -ErrorAction SilentlyContinue
}
if($svc.Status -ne "Running")
{
    Write-Host "Starting Solr service"
    Start-Service "$solrSvcName"
}




Copy-Item "c:\solr\server\solr\configsets\_default" "c:\solr\server\solr\configsets\sitecore_main" -recurse
Copy-Item "c:\solr\server\solr\configsets\_default" "c:\solr\server\solr\configsets\sitecore_xdb" -recurse

	$xml = New-Object XML
	$path = "c:\solr\server\solr\configsets\sitecore_main\conf\managed-schema"
	$xml.Load($path)
				
	$uniqueKey =  $xml.SelectSingleNode("//uniqueKey")
	$uniqueKey.InnerText = "_uniqueid"
				
	$field = $xml.CreateElement("field")
	$field.SetAttribute("name", "_uniqueid")
	$field.SetAttribute("type", "string")
	$field.SetAttribute("indexed", "true")
	$field.SetAttribute("required", "true")
	$field.SetAttribute("stored", "true")
				
	$xml.DocumentElement.AppendChild($field)
				
	$xml.Save($path)



$secureCertPassw = ConvertTo-SecureString -AsPlainText -Force ("$solrCertPass")
Import-PfxCertificate -FilePath "$solrRoot\server\etc\solr-ssl.pfx" -CertStoreLocation Cert:\LocalMachine\Root -Password $secureCertPassw
New-NetFirewallRule -DisplayName "Allow solr-in - 8984 " -Direction Inbound -LocalPort $solrPort -Protocol TCP -Action Allow