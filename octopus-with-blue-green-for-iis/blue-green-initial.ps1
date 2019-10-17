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


$state = Get-ActiveWebSite 
     switch ($state) 
      {
           "$activescwebport1"
             { 
               $deployTo = (get-website (Get-WebSiteNameByPort  -port  $activescwebport2))
                if ($deployTo)
                            {
                            set-octopusVariable -Name iissitename    -value $($deployTo.name)
                            set-octopusVariable -Name iispoolname    -value $apppool82
                            set-octopusVariable -Name SwitchoverPort -value $activescwebport2
                            }
                                else 
                                   {
                                    $iissitename = $OctopusParameters["IIS_siteName"]  + '_' + $blueWebPrefix
                                    set-octopusVariable -Name iissitename    -value $iissitename
                                    set-octopusVariable -Name iispoolname    -value $apppool82
                                    set-octopusVariable -Name SwitchoverPort -value $activescwebport2
                                    }
             } 
           "$activescwebport2"
             {
               $deployTo = (get-website (Get-WebSiteNameByPort  -port  $activescwebport1))
                if ($deployTo)  
                            {
                            set-octopusVariable -Name iissitename    -value $($deployTo.name)
                            set-octopusVariable -Name iispoolname    -value $apppool81
                            set-octopusVariable -Name SwitchoverPort -value $activescwebport1
                            }

             }
           'RuleNotExist'
             {        
                                    $iissitename =  $OctopusParameters["IIS_siteName"] + '_' + $greenWebPrefix
                                    set-octopusVariable -Name iissitename    -value $iissitename
                                    set-octopusVariable -Name iispoolname    -value $apppool81
                                    set-octopusVariable -Name SwitchoverPort -value $activescwebport1
             }

            Default {}
     }   

}

    else {
            Write-Output "ARR extension for IIS hasn't been found.."
            Write-Output "Continue deployment without this script logic (with defined octopus variables)"

            set-octopusVariable -Name iissitename -value $OctopusParameters["IIS_siteName"]
            set-octopusVariable -Name iispoolname -value $OctopusParameters["IIS_poolName"]
            set-octopusVariable -Name httpPort    -value '80'
            set-octopusVariable -Name httpsPort   -value '443'
        }

