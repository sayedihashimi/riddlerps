[cmdletbinding(SupportsShouldProcess=$true)]
param()

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

$script:scriptDir = ((Get-ScriptDirectory) + "\")

$global:riddlerpssettings = New-Object psobject -Property @{    
    MessagePrefix = '  '
    TemplateRoot = (Join-Path ($script:scriptDir) -ChildPath 'templates-v1\Add Project')
    IndentLevel = 1
    WhatIf = $true
    QuitResultKey = 'rps-quit'
}

#######################################################################
# Functions dealing with user input/output
#######################################################################

function Invoke-Prompts{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        $prompts,

        [Parameter(Position=1)]
        [int]$indentLevel=1
    )
    process{
        $private:results = @{}
        
        $requiredPrompts = $prompts | Where-Object { !($_.Type) -or ($_.Type -ne 'optional') }
        $optionalPrompts = $prompts | Where-Object { $_.Type -and ($_.Type -eq 'optional') }

        $requiredPrompts | ForEach-Object {
            $prompt = $_
            $result = Get-PromptResult -prompt $prompt -indentLevel $indentLevel
            foreach($key in $result.Keys){
                if($prompt.PromptType -eq 'PickMany'){
                    $private:results[$key]=$result[$key]
                }
                else{
                    $private:results[$key]=$result[$_.Name]
                }
                
            }
        }

        if($optionalPrompts){
            # optional prompts exist, see if the user want's to answer the questions
            Write-MessagePrefix -indentLevel $indentLevel
            'Show all options?' | Write-Host
            Write-InputPromptText -indentLevel $indentLevel

            $showAllOptoins = ConvertTo-Bool (Get-TextFromUser)
            ' ' | Write-Host

            # loop through optional prompts, only prompt if user accepts.
            $optionalPrompts | ForEach-Object {
                $prompt = $_
                if($showAllOptoins){
                    $result = Get-PromptResult -prompt $prompt -indentLevel $indentLevel
                    foreach($key in $result.Keys){
                        $results[$key]=$result[$_.Name]
                    }
                }
            }
        }

        # apply default values here
        foreach($key in $result.Keys){
            if($result[$key] -eq $null){
                $results[$key]=$prompt.Default
            }
        }

        # return results
        $results
    }
}

function Write-MessagePrefix{
    [cmdletbinding()]
    param(
        [Parameter(Position=0)]
        $indentLevel = 1
    )
    process{
        [string]$prefix=$global:riddlerpssettings.MessagePrefix
        $prefix = ($prefix*$indentLevel)
        $prefix | Write-Host -NoNewline
    }
}

function Write-InputPromptText{
    [cmdletbinding()]
    param(
        [Parameter(Position=0)]
        $indentLevel = 1
    )
    process{
        Write-MessagePrefix -indentLevel $indentLevel
        '>> ' | Write-Host -ForegroundColor Green -NoNewline
    }
}

function Get-PromptResult{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        $prompt,

        [Parameter(Position=1)]
        $indentLevel = 1,

        $promptForgroundColor = 'Cyan'
    )
    process{
        $name = $prompt.Name
        $result = @{}
        $private:results = @{}

        # display text/options
        Write-MessagePrefix -indentLevel $indentLevel
        "{0}" -f $prompt.Text| Write-Host -ForegroundColor $promptForgroundColor
        $options = $prompt.Options
        $getValFromUser = $true
        if($prompt.Options){
            $optionsType = $options.Type
            if(-not $optionsType){$optionsType = 'Numbered'}

            if($optionsType -eq 'Numbered'){
                $counter = 0
                
                foreach($key in $prompt.Options.Keys){
                    if($key -eq 'Type'){ continue }

                    if( !($options -is [hashtable]) ){
                        if($options -is [array] -and $options.Length -gt 1){
                            $options = $options[1]
                        }
                    }
                    Write-MessagePrefix -indentLevel $indentLevel
                    '{0}={1}' -f $key, $options[$key] | Write-Host
                }                
            }
            else{                
                $optStr = (ConvertTo-OptionsString -options $options)
                $promptResult = Prompt-OptionsString -optionsString $optStr -optionsType $optionsType

                foreach($key in $promptResult.Keys){
                    $results[$key]=$true
                }
                if($optionsType -eq 'PickOne'){
                    $result[$prompt.Name]=($promptResult.Keys | Select-Object -First 1)
                }
                elseif($optionsType -eq 'PickMany'){
                    foreach($key in $promptResult.Keys){
                        $result[$key]=$key
                    }
                }
                $getValFromUser = $false
            }
        }
        
        if($getValFromUser){
            Write-InputPromptText -indentLevel $indentLevel

            # get the value from the user
            if($prompt.PromptAction -is [scriptblock]){
                $valFromUser = (&($prompt.PromptAction))
            }
            else{
                
                if($options){
                    $valFromUser=($options[(Read-Host)])
                }
                else{
                    $valFromUser= Read-Host
                }
            }

            ' ' | Write-Host
            if($valFromUser -eq $null){ $valFromUser=$prompt.Default }

            $result[$prompt.Name]=$valFromUser
        }

        return $result
    }
}

function Write-PromptsSummary {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $prompts,
        [Parameter(Position=1)]
        $indentLevel = 1
    )
    process{
        Write-MessagePrefix -indentLevel $indentLevel
        # for now just return this so it's displayed directly
        'Prompt results' | Write-Host -ForegroundColor Green
        $prompts <#| Select-Object text,name#>
    }
}

function Get-TextFromUser{
    [cmdletbinding()]
    param()
    process{
        Read-Host
    }
}

function Report-FakeProgress{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
        $message,
        [Parameter(Position=1)]
        $totalSeconds = 2
    )
    process{
        $seconds = 0
        $message | Write-Host
        while($seconds -lt $totalSeconds){
            '.........................' | Write-Host -NoNewline -ForegroundColor Green
            Start-Sleep 1
            $seconds++
        }
        "`n" | Write-Host
    }
}

function Get-RelativePath{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [IO.DirectoryInfo]$from,

        [Parameter(Mandatory=$true)]
        [IO.DirectoryInfo]$to
    )
    process{
        Push-Location

        Set-Location $from.FullName

        # compute the relative path
        $relPathToTemplateFile = (Get-Item $to.FullName | Resolve-Path -Relative)
        $relPathToTemplateFile

        Pop-Location
    }
}

function ConvertTo-Bool{
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$valueToConvert
    )
    process{
        $truePattern = 'true|t|1|y[es]|y'
        $falsePattern = 'false|f|0|n[o]|n'       

        if($valueToConvert -match $truePattern){
            $valueToReturn = $true   
        }
        elseif($valueToConvert -match $falsePattern){
            $valueToReturn = $false
        }
        elseif(-not $valueToConvert){ <# ignore it#> }
        else{
            throw ('Unknown bool value to convert: [{0}]' -f $valueToConvert)
        }

        $valueToReturn
    }
}

#######################################################################
# Functions relating to displaying/reading optoins
#######################################################################

function ConvertTo-OptionsString{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $options
    )
    process{
        $optionsType = $options.Type
        if(-not $optionsType){ $optionsType = 'PickOne' }

        if($optionsType -eq 'PickOne'){
            $delims = @('  (',')')
        }
        else{
            $delims = @('  [',']')
        }
        $str = ''

        foreach($key in $options.Keys){
            if($key -eq 'Type'){continue}

            $str+=( '{0}${2}$ {1} {3}{4}' -f $delims[0], $delims[1],$key,$options[$key],"`n")
        }

        $str
    }
}

function Prompt-OptionsString{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        $optionsString,
        [Parameter(Position=1)]
        $optionsType='PickMany'
    )
    process{
        $parsedOptions = Parse-OptonsString -optionsString $optionsString
        $displayPoints = @()
        # now we have the parsed options

        $str = $parsedOptions.TransformedOptionsString

        $currentIndex = 0
        foreach($m in $parsedOptions.MatchedPoints){
            $str.substring($currentIndex,$m.Position-$currentIndex) | Write-Host -NoNewline
            $currentIndex = $m.Position

            $displayPoints += @{
                Name = $m.Name
                Position=$m.Position
                CursorPosition=$Host.UI.RawUI.CursorPosition
                Value = $null
            }
        }
        $str.substring($currentIndex,$str.length-$currentIndex) | Write-Host -NoNewline
        
        if($optionsType -eq 'PickMany'){
            '  <<select options and press enter>>' | Write-Host -ForegroundColor Gray
        }

        # set cursor to the first match        
        $oldPos = $Host.UI.RawUI.CursorPosition
        $Host.UI.RawUI.CursorPosition = $displayPoints[0].CursorPosition
        $continueLoop = $true
        $boundaries = @{
            X = @{
                Min = ($displayPoints.CursorPosition.X | Measure-Object -Minimum).Minimum
                Max = ($displayPoints.CursorPosition.X | Measure-Object -Maximum).Maximum
            }
            Y = @{
                Min = ($displayPoints.CursorPosition.Y | Measure-Object -Minimum).Minimum
                Max = ($displayPoints.CursorPosition.Y | Measure-Object -Maximum).Maximum
            }
        }
        
        $oldCursorSize = $Host.UI.RawUI.CursorSize
        $oldFgColor = $Host.ui.RawUI.ForegroundColor
        $Host.UI.RawUI.ForegroundColor = 'Yellow'
        $results = @{}
        if($GitPromptSettings){
            $GitPromptSettings.DefaultForegroundColor = $Host.UI.RawUI.ForegroundColor
        }
        while($continueloop){
            $Host.UI.RawUI.CursorSize = 100
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $pos = $Host.UI.RawUI.CursorPosition
            if( @(81,27).Contains($key.VirtualKeyCode) ){
                # q, Esc
                $continueloop = $false
                $results[($global:riddlerpssettings.QuitResultKey)]=$true
                break
            }
            elseif($optionsType -eq 'PickMany' -and $key.VirtualKeyCode -eq 13){
                # Enter key for PickMany
                $continueloop = $false
                break
            }
            elseif($key.VirtualKeyCode -eq 38){
                # Up arrow key
                if(([int]($pos.Y)-1) -ge $boundaries.Y.Min){
                    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates -ArgumentList @($pos.X,([int]($pos.Y)-1))    
                }                
            }
            elseif($key.VirtualKeyCode -eq 40){
                # down arrow
                if(([int]($pos.Y)+1) -le $boundaries.Y.Max){
                    $Host.UI.RawUI.CursorPosition = New-Object System.Management.Automation.Host.Coordinates -ArgumentList @($pos.X,([int]($pos.Y)+1))
                }
            }
            elseif(
                ($key.VirtualKeycode -ge 48 -and $key.VirtualKeyCode -le 90) -or 
                ($key.VirtualKeyCode -eq 32) -or 
                ($key.VirtualKeyCode -eq 13)){
                # any key 0-9 or a-z; spacebar (32); Enter (13)
                $nowPos = $Host.UI.RawUI.CursorPosition
                $setValue = $false
                foreach($p in $displayPoints){
                    $cPos = $p.CursorPosition
                    if($cPos.X -eq $nowPos.X -and $cPos.Y -eq $nowPos.Y){
                        # toogle the value of the text
                        $rect = New-Object 'System.Management.Automation.Host.Rectangle' -ArgumentList @($cPos.x,$cPos.y,$cPos.x,$cPos.y)
                        $currentChar = $Host.UI.RawUI.GetBufferContents($rect).Character
                        if($currentChar -eq 'X'){
                            ' ' | Write-Host
                        }
                        else{
                            'X' | Write-Host
                            $setValue = $true
                            if($optionsType -eq 'PickOne'){
                                $continueLoop = $false
                            }
                        }
                    }
                }

                if($optionsType -eq 'PickOne' -and $setValue){
                    $tpos = $Host.UI.RawUI.CursorPosition
                    foreach($p in $displayPoints){
                        $cPos = $p.CursorPosition
                        if(-not ($cPos.X -eq $nowPos.X -and $cPos.Y -eq $nowPos.Y)){
                            $Host.UI.RawUI.CursorPosition=New-Object System.Management.Automation.Host.Coordinates -ArgumentList @($cPos.X,$cPos.Y)
                            ' ' | Write-Host
                        }
                    }
                    $Host.UI.RawUI.CursorPosition = $tpos             
                }

                $Host.UI.RawUI.CursorPosition = $nowPos
            }
            else{
                # unknown key, just ignore it
            }
        }

        $Host.UI.RawUI.ForegroundColor = $oldFgColor
        if($GitPromptSettings){
            $GitPromptSettings.DefaultForegroundColor = $Host.UI.RawUI.ForegroundColor
        }

        $Host.UI.RawUI.CursorSize = $oldCursorSize
        $Host.UI.RawUI.CursorPosition = $oldPos
        
        # now loop through display points and see if they have some text
        foreach($displayPoint in $displayPoints){        
            $p = $displayPoint.CursorPosition
            [int]$x = $p.x
            [int]$y = $p.y
            $rect = New-Object 'System.Management.Automation.Host.Rectangle' -ArgumentList @($x,$y,$x,$y)
            $displayPoint.Value = $host.ui.RawUI.GetBufferContents($rect).Character
        }
        
        $selectedOptions=@()
        $displayPoints | Where-Object {$_.Value -and $_.Value -ne ' '} | ForEach-Object{
            $results[$_.Name]=$_.Value

            # for some reason if I take this out it doesn't work any longer?
            ' ' |Write-Host
            $selectedOptions += $_.Name
        }
        'results: [{0}]' -f ($results.Keys -join ';') | Write-Verbose
        $results
    }
}

function New-PromptObject{
    [cmdletbinding()]
    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName =$true)]
        $name = 'userprompt',

        [Parameter(Position=1,Mandatory=$true,ValueFromPipelineByPropertyName =$true)]
        $text,

        [Parameter(Position=2,ValueFromPipelineByPropertyName =$true)]
        [ValidateSet("Question","PickOne","PickMany",'Bool',"Ordered")]
        $promptType = "Question",

        [Parameter(Position=3,ValueFromPipelineByPropertyName =$true)]
        $options,

        [Parameter(Position=4,ValueFromPipelineByPropertyName=$true)]
        [ScriptBlock]$promptAction,
        $defaultValue,

        [Parameter(Position=5,ValueFromPipelineByPropertyName=$true)]
        [bool]$optional = $false
    )
    process{
        
        # Convert Bool type to a PickOne
        if($promptType -eq 'Bool'){
            $promptAction = ({ ConvertTo-Bool(Get-TextFromUser) })

            $promptType = 'PickOne'

            if(-not $defaultValue){
                $defaultValue = 'no'
            }

            $options = ([ordered]@{
                            'yes'='Yes'
                            'no'='No'
                        })
        }

        # we need to add the type to the options object
        if($options -is [hashtable] -or
            $options -is [System.Collections.Specialized.OrderedDictionary]){
                $options['type']=$promptType
            }

        $typeToAdd = $null
        
        New-Object psobject -Property @{
            Name = $name
            Text = $text
            Default = $defaultValue
            Options = $options
            PromptType = $promptType
            PromptAction=$promptAction
            Type = $typeToAdd
        }
    }
}

function Parse-OptonsString{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $optionsString
    )
    process{
        $matchedPoints = @()
        $newOptionsStr = ''
        $regex=[regex] '(?<options>\$[^\$]+\$)'

        $currentIndex = 0
        $allMatches = $regex.Matches($optionsString)
        foreach($match in $allMatches){
            $group = $match.Groups['options']
            if($group.Success){
                $length = $group.Index + $group.Length - $currentIndex

                $newOptionsStr+=$optionsString.Substring($currentIndex,$group.Index - $currentIndex)
                $matchedPoints += @{
                    Name = $group.value.substring(1,$group.value.length-2)
                    Position = $newOptionsStr.Length
                }
                $currentIndex += $length
            }
        }

        $newOptionsStr += $optionsString.substring($currentIndex,$optionsString.length - $currentIndex)
        @{
            OptionsString = $optionsString
            TransformedOptionsString = $newOptionsStr
            MatchedPoints = $matchedPoints
        }
    }
}