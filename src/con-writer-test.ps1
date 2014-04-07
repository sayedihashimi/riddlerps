
[cmdletbinding()]
param()

# write out some options

$points = @()
'Which frameworks do you want to include' | Write-Host
'  ['  |Write-Host -NoNewline

$points += $Host.UI.RawUI.CursorPosition
' ] MVC'

'  ['  |Write-Host -NoNewline

$points += $Host.UI.RawUI.CursorPosition
' ] Web Forms'


'  ['  |Write-Host -NoNewline

$points += $Host.UI.RawUI.CursorPosition
' ] Web API'


$currentPos = $Host.UI.RawUI.CursorPosition

$Host.UI.RawUI.CursorPosition = $points[0]

$continueloop = $true
while($continueloop){
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $pos = $Host.UI.RawUI.CursorPosition
    if($key.Character -eq 'q'){
        $continueloop = $false
        break
    }
    elseif($key.VirtualKeyCode -eq 38){
        # Up arrow key
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates -ArgumentList @($pos.X,([int]($pos.Y)-1))
    }
    elseif($key.VirtualKeyCode -eq 40){
        $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates -ArgumentList @($pos.X,([int]($pos.Y)+1))
    }
    elseif($key.VirtualKeycode -eq 88){
        $nowPos = $Host.UI.RawUI.CursorPosition
        
        foreach($p in $points){
            if($p.X -eq $nowPos.X -and $p.Y -eq $nowPos.Y){
                'X' | Write-Host
                $Host.UI.RawUI.CursorPosition = $nowPos
            }
        }
    }
    else{
        $key.VirtualKeyCode | Write-Host
    }
}

$Host.UI.RawUI.CursorPosition =$currentPos
