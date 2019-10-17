import-module webadministration
#&$env:systemroot\system32\inetsrv\appcmd set config  -section:system.webServer/proxy /enabled:"True"  /commit:apphost

$arr = &$env:systemroot\system32\inetsrv\appcmd  list modules 'ApplicationRequestRouting'
if ($arr) 
    {

$balancerport             = '80'
$balancersslport          = '443'
$activescwebport1         = '81'
$activescwebport2         = '82'
$apppool81                = 'app-pool81'
$apppool82                = 'app-pool82'
$greenWebPrefix           = 'green'
$blueWebPrefix            = 'blue'
$idleWebPrefix            = 'idle'
$balancerWebSiteName      = "frontEndBalancer80-443"
$balancerWebPhysicalPath  = 'C:\inetpub\wwwroot'
$balancerCertThumbprint   = '‎e803eee2d69083207a30a90529852af861deed0e'
$ruleConfigFileName       = 'web.config'


#check if default http/https website exist
function Check-FrontEndBalancerSite {
$frontEndBalancerSite = (get-website | ? {$_.Bindings.Collection.bindingInformation -match $balancerport})
    if (!$frontEndBalancerSite)  
        {
        New-WebAppPool -Name $balancerWebSiteName  -force  -erroraction silentlycontinue
        new-website    -name $balancerWebSiteName -PhysicalPath $balancerWebPhysicalPath -Port $balancerport -ApplicationPool $balancerWebSiteName
        $balancerCert   = get-childitem Cert:\LocalMachine\my|?{$_.Thumbprint -eq $balancerCertThumbprint}
        $newBindings    = New-WebBinding -Name $balancerWebSiteName -Protocol "https" -Port $balancersslport
        New-Item -Path "IIS:\SslBindings\!$balancersslport!" -Value $balancerCert
        }
    }

function Set-ActiveWebSite ($activePort) {
$ruleconfigPath = "$balancerWebPhysicalPath\$ruleConfigFileName"

[xml]$rule1 ='<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="ReverseProxyInboundRule1">
                    <match url="(.*)" />
                    <action type="Rewrite" url="http://localhost:port/{R:1}" />
                </rule>
            </rules>
        </rewrite>
    </system.webServer>
</configuration>
'
$url = $rule1.configuration.'system.webServer'.rewrite.rules.rule.action.url
$url = $url -replace 'port',$activePort
$rule1.configuration.'system.webServer'.rewrite.rules.rule.action.url = $url
$rule1.Save("$ruleconfigPath")
   }

function Get-ActiveWebSite ($activePort) {

    $ruleconfigPath = "$balancerWebPhysicalPath\$ruleConfigFileName"

    if (gci $ruleconfigPath -erroraction silentlycontinue)
            {
             [xml]$rule      = get-content $ruleconfigPath
             $length         = ($rule.configuration.'system.webServer'.rewrite.rules.rule.action.url).Length
             $ruleActivePort = (($rule.configuration.'system.webServer'.rewrite.rules.rule.action.url).Substring(0,$length-6)) -replace ".*:"
             return $ruleActivePort
            }
            else {
                   return "RuleNotExist"
                   }
    }

function Get-WebSiteNameByPort ($port) {

$getWeb = (get-website | ? {$_.Bindings.Collection.bindingInformation -match ":$port"})

    if ($getWeb) 
        {
        return "$($getWeb.name)"
        }
            else
                  {
                  return $false
                  }
}

function Change-WebsiteName ($oldname,$newname) { 
        try {
        Push-Location "$env:systemroot\SysWOW64\inetsrv"
        .\appcmd.exe set site $oldname -name:$newname
        Pop-Location
            }
                catch
                    {
                    write-host "name can't be changed, error: $($error[0].exception)"
                    }
}


            $SwitchoverPort = $OctopusParameters['Octopus.Action[Detect ARR and Set web bindings].Output.SwitchoverPort']
            $iissitename    = $OctopusParameters['Octopus.Action[Detect ARR and Set web bindings].Output.iissitename']
            $iispoolname    = $OctopusParameters['Octopus.Action[Detect ARR and Set web bindings].Output.iispoolname']



            $currentActivePort = $activescwebport1,$activescwebport2 | ? {$_ -ne $SwitchoverPort}
            $currentActiveSite = Get-Website (Get-WebSiteNameByPort -port $currentActivePort)
            if ($currentActiveSite) 
                    {
                            if (($currentActiveSite.name).Contains("_$greenWebPrefix")) 
                                { 
                                    $currentActiveSiteToIdle = $($currentActiveSite.Name) -replace "_$greenWebPrefix","_$idleWebPrefix"
                                    $currentActiveSiteToBlue = $($currentActiveSite.Name) -replace "_$greenWebPrefix","_$blueWebPrefix"
                                }

                            $iissitenameGreen  = $iissitename -replace "_$blueWebPrefix","_$greenWebPrefix"
                            
                            write-host "currently green/active web site name is: $($currentActiveSite.name) "
                            write-host "temporarily renaming $($currentActiveSite.name) to $currentActiveSiteToIdle"
                            Change-WebsiteName -oldname  $($currentActiveSite.name) -newname $currentActiveSiteToIdle;start-sleep -seconds 1.5
                            
                            write-host "changing this deployment website: $iissitename to $iissitenameGreen"
                            Change-WebsiteName -oldname  $iissitename               -newname $iissitenameGreen;start-sleep -seconds 1.5
                            
                            write-host "lastly, changing  idle: $currentActiveSiteToIdle to  blue state: $currentActiveSiteToBlue"
                            Change-WebsiteName -oldname  $currentActiveSiteToIdle   -newname "$currentActiveSiteToBlue"
                                
                    }

                    write-host "set inbound rule this deployed web site, see web.config file under default web site which works under 80/443 port"
                    Set-ActiveWebSite  -activePort $SwitchoverPort 
                    Start-WebAppPool -Name $iispoolname
                    Start-Website -Name $iissitenameGreen
}

    else 
        {
            Write-Output "ARR extension for IIS hasn't been found.."
            Write-Output "Continue deployment without this script logic (with defined octopus variables)"

            set-octopusVariable -Name iissitename     -value $IIS_siteName
            set-octopusVariable -Name iispoolname     -value $IIS_poolName
            set-octopusVariable -Name SwitchoverPort  -value '80'
            set-octopusVariable -Name httpPort        -value '80'
            set-octopusVariable -Name httpsPort       -value '443'
        }
