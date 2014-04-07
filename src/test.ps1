$moduleName = 'riddlerps'
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$scriptDir = ((Get-ScriptDirectory) + "\")

# dotsorce the install.ps1
. (Join-Path $scriptDir .\install.ps1 | Resolve-Path)

$optionsString = @'
Select the frameworks you want
    [$addmvc$ ] MVC
    [$webforms$ ] Web Forms
    [$webapi$ ] Web API

'@

$selectedOptions = Prompt-OptionsString -optionsString $optionsString

#$selectedOptions

$options = [ordered] @{
    'Type'='PickOne'
    'Add project'='Add project'
    'Add file'='Add file'
    'Install generator'='Install generator'
    'Help'='Help'
    'Quit'='Quit'
}

$Options=[ordered]@{
                'Type'='PickMany'
                'unittest' = 'Add unittests'
                'addmvc' = 'Add mvc'
                'addwebapi' = 'Add Web API'
                'addwebforms' = 'Add Web Forms'
            }

$optionsString = Convert-ToOptionsString -options $options
Prompt-OptionsString -optionsString $optionsString

$prompts = @(New-Object psobject @{
            Name='foo'
            Options=[ordered]@{
                'Type'='PickOne'
                'unittest' = 'Add unittests'
                'addmvc' = 'Add mvc'
                'addwebapi' = 'Add Web API'
                'addwebforms' = 'Add Web Forms'
            }
        })

Invoke-Prompts -prompts $prompts


