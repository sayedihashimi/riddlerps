$moduleName = 'riddlerps'
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$scriptDir = ((Get-ScriptDirectory) + "\")

# dotsorce the install.ps1
. (Join-Path $scriptDir ..\.\install.ps1 | Resolve-Path)



$prompt = (New-PromptObject -name 'Unit tests' -promptType PickOne -text 'Unit tests?' `
    -options([ordered]@{
        'yes'='Yes'
        'no'='No'
    }) `
    -promptAction { ConvertTo-Bool(Get-TextFromUser) } )
    
Invoke-Prompts $prompt