
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$scriptDir = ((Get-ScriptDirectory) + "\")


Get-ChildItem $scriptDir -Include '*.suo' -Hidden -Recurse | Remove-Item -Force
Get-ChildItem $scriptDir -Include 'bin'-Recurse | Remove-Item -Force -Recurse
Get-ChildItem $scriptDir -Include 'obj'-Recurse | Remove-Item -Force -Recurse
Get-ChildItem $scriptDir -Include '*.user' -Recurse | Remove-Item -Force -Recurse



