[cmdletbinding()]
param()

$moduleName = 'riddlerps'
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$scriptDir = ((Get-ScriptDirectory) + "\")

# dotsorce the install.ps1
. (Join-Path $scriptDir ..\.\install.ps1 | Resolve-Path)

$script:kmImported = $false

function Write-UserCommand{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $text
    )
    process{
        "$text`r`n" | Write-Host -ForegroundColor Green
    }
}

function Ensure-KVMImported{
    [cmdletbinding()]
    param()
    process{
        if(!$script:kvmImported){
            'Importig kvm' | Write-Verbose
            # . source to get access to the functions in kvm.ps1
            . kvm | Out-Null

            $script:kvmImported = $true
        }
    }
}

function install-global{
    [cmdletbinding()]
    param()
    process{
        'Installing KVM from the web.' | Write-Verbose
        'Installing kvm from https://github.com/aspnet/home' | Write-UserCommand
        powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/aspnet/Home/master/kvminstall.ps1'))"
    }
}
function kvm-list{
    [cmdletbinding()]
    param()
    process{
        # show installed versions
        kvm list

        # lets get the list of remote packages and show those as well
        $feed = "https://www.myget.org/F/aspnetvnext/api/v2";
        $platform = 'svr50'
        $architecture = 'x86'
        $url = "$feed/GetUpdates()?packageIds=%27KRE-$platform-$architecture%27&versions=%270.0%27&includePrerelease=true&includeAllVersions=true"

        $wc = New-Object System.Net.WebClient
        $wc.Credentials = new-object System.Net.NetworkCredential("aspnetreadonly", "4d8a2d9c-7b80-4162-9978-47e918c9658c")
        Add-Proxy-If-Specified($wc)
        [xml]$xml = $wc.DownloadString($url)

        $xml.feed.entry.properties.Version | Write-Host -ForegroundColor Green
    }
}
function update-kvm-latest{
    [cmdletbinding()]
    param()
    process{
        $prompt = New-PromptObject -name 'action' `
            -text 'Select options' `
            -promptType PickMany `
            -options ([ordered]@{
                'Type'='PickMany'
                'persistent'='Persistent (add KRE bin to PATH environment variables persistently)'
                'global'='Global (install to machine-wide location)'
                'force'='Force (install even if specified version is already installed)'
            })
            $promptResult = Invoke-Prompts $prompt
            
            $strCmd = 'kvm install latest'
            if($promptResult['persistent']){ $strCmd += ' -p' }
            if($promptResult['global']){$strCmd += ' -g' }
            if($promptResult['force']){$strCmd += ' -f'}

            Invoke-Expression $strCmd

            $strCmd | Write-UserCommand
    }
}

function restore-pkgs{
    [cmdletbinding()]
    param()
    process{
        kpm restore

        'kpm restore' | Write-UserCommand
    }
}

function build-project{
    [cmdletbinding()]
    param()
    process{        
        kpm build

        'kpm build' | Write-UserCommand
    }
}

function new-project{
    [cmdletbinding()]
    param()
    process{
        yo aspnet
    }
}
<#
$prompt = New-PromptObject -name 'action' `
            -text 'Select options' `
            -promptType PickMany `
            -options ([ordered]@{
                'Type'='PickMany'
                'persistent'='Persistent (add KRE bin to PATH environment variables persistently)'
                'global'='Global (install to machine-wide location)'
                'force'='Force (install even if specified version is already installed)'
            })
$promptResult = Invoke-Prompts $prompt
exit
#>


$p = New-PromptObject `
        -promptType PickOne `
        -text 'How can I help you?' `
        -options ([ordered]@{
            'install-global'='Install (global) KVM from the web'
            'update-kvm-latest'='Update kvm to latest'
            'kvm-list'='List KVM versions'
            'new-project'='Create a new project'
            'restore-pkgs'='Restore NuGet packages'
            'build-project'='Build project'
        })

$action = (Invoke-Prompts $p)['userprompt']

if(!$action -or ($action -eq 'rps-quit')) {
    exit
}

&$action