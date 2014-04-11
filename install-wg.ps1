$moduleName = 'web-generator'
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$scriptDir = ((Get-ScriptDirectory) + "\")

function Add-ModulePrivate{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,Position=1)]
        $modulePath,
        [Parameter(Mandatory=$true,Position=2)]
        $moduleName
    )
    process{
        if(Test-Path $modulePath){
            "Importing [{0}] module from [{1}]" -f $moduleName, $modulePath | Write-Verbose

            if((Get-Module $moduleName)){
                Remove-Module $moduleName
            }
    
            Import-Module $modulePath -PassThru -DisableNameChecking | Out-Null
        }
        else{
            'Unable to find [{0}] module at [{1}]' -f $moduleName, $modulePath | Write-Error
	        return
        }
    }
}


# Import riddlerps
$riddlerInstallPath= ((Join-Path -Path $scriptDir -ChildPath ('.\install.ps1')) | Resolve-Path)
Add-ModulePrivate -modulePath $riddlerInstallPath -moduleName ((Get-Item $riddlerInstallPath).Name)

# Import web-generators
$webGenModPath = ((Join-Path -Path $scriptDir -ChildPath ("{0}.psm1" -f $moduleName)) | Resolve-Path )
Add-ModulePrivate -modulePath $webGenModPath -moduleName ((Get-Item $webGenModPath).Name)
