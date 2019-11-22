


#from : https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site

$filePathForCert = "C:\certs\AzureP2SRootCert-publicKey.cer"

#generate private key
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=AzureP2SRootCert"  -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign


#generate client certificate based on above private key
New-SelfSignedCertificate -Type Custom  -KeySpec Signature `
-Subject "CN=AzureP2SClienttCert"  -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")



$filePathForCert = $filePathForCert
$cert = new-object System.Security.Cryptography.X509Certificates.X509Certificate2($filePathForCert)
$CertBase64 = [system.convert]::ToBase64String($cert.RawData)
$p2srootcert = New-AzureRmVpnClientRootCertificate -Name $P2SRootCertName -PublicCertData $CertBase64


#before using makecert you should install SDK 
makecert -sky exchange -r -n "CN=Azure-Root-Certificate" -pe -a sha1 -len 2048 -ss My

makecert.exe -n "CN=Azure-Client-Certificate" -pe -sky exchange -m 96 -ss My -in "Azure-Root-Certificate" -is my -a sha1