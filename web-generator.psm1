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
}

function Invoke-WebGenerator {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param()
    begin{}
    process{

        $global:riddlerpssettings.IndentLevel = 1
        $prompts = @(
        (New-Object psobject -Property @{
            Name='action'
            Text = '
Welcome to ASP.NET vNext

  What would you like to do?
  '
            Options = [ordered] @{
                'Type'='PickOne'
                'Add project'='Add project'
                'Add file'='Add file'
                'Install generator'='Install generator'
                'Help'='Help'
                'Quit'='Quit'
            }
            Default='Quit'
        }))
        
        $promptResult = Invoke-Prompts $prompts -indentLevel $global:riddlerpssettings.IndentLevel

        switch ($promptResult['action']){
            'Add project' { Add-Project  }
            'Add file' { Add-File }
            'Install generator' { Install-Generator }
            'Help' { KGen-Help }
            'Quit' { KGen-Quit }
            default{ throw  ('Unknown choice: [{0}]' -f  $selectedOption) }
        } 
    }
}

function Add-Project {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        [switch]$showAllPrompts
    )
    process{
        <#
        questions:

        project name
        project type: mvc/web forms/mvc
        unit test: yes/no
        HasMvc
        HasWebApi
        HasWebForms
        AuthType: WindowsAuth/None/IndividualAuth/OrgAuth
        #>

        $prompts = @((New-Object psobject -Property @{
            Name='projname'
            Text = 'Project name?'
            Default='webapp'
        }),
        (New-Object psobject -Property @{
            Name='projtype'
            Text = 'Project type?'
            Options = [ordered]@{'Type'='PickOne';'Empty'='Empty';'WebForms'='WebForms';'MVC'='MVC';'Web API'='Web API';'SPA'='SPA';'Facebook'='Facebook'}
            Default = 'Empty'
        }),
        (New-Object psobject @{
            Name='fxlist'
            Text='Select Frameworks'
            Options=[ordered]@{
                'Type'='PickMany'
                'addmvc' = 'Add mvc'
                'addwebapi' = 'Add Web API'
                'addwebforms' = 'Add Web Forms'
            }
        }),
        (New-Object psobject -Property @{
            Name = 'unittest'
            Text='Do you want to add a unit test project?'
            PromptAction = {
                # you can have a custom action for your prompt as well
                ConvertTo-Bool(Get-TextFromUser)
            }
            Default=$false
        })
        )

        $promptResults = Invoke-Prompts $prompts -indentLevel 1

        $ctx = Get-GeneratorContext
        $ctx.Keys | ForEach-Object{
            if(-not ($promptResults[$_])){
                $promptResults[$_]=$ctx[$_]
            }
        }

        Add-ProjectContent -parameters $promptResults -indentLevel 1
    }
}

function Write-ProjectMessage{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
        $message
    )
    process{
        $message | Write-Host -ForegroundColor Green
    }
}

function Add-File{
    [cmdletbinding()]
    param()
    process{
        'Inside of Add-File'
    }
}

function Get-GeneratorContext{
    [cmdletbinding()]
    param()
    process{
        $ctxValues = @{
            pwd = $pwd
            templateRoot = ($global:riddlerpssettings.TemplateRoot)
        }

        $ctxValues
    }
}
#######################################################################
# Misc functions for the main prompt
#######################################################################
function KGen-Help{
    [cmdletbinding()]
    param()
    process{
        'Help here'
    }
}
function KGen-Quit{
    [cmdletbinding()]
    param()
    process{
        'Quit'
    }
}
function Install-Generator{
    [cmdletbinding()]
    param()
    process{
        'Help here'
    }
}

#######################################################################
# Functions that add content
#######################################################################
function Add-ProjectContent {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Position=0,
                   ValueFromPipeline=$true)]
        $parameters,
        [Parameter(Position=1)]
        $indentLevel = 1
    )
    process{
        $projectName = $parameters['projname']
        $targetFolder = join-path -path (get-item ($parameters['pwd'])) -ChildPath $projectName

        'Creating project {0} in {1}' -f $projectName, $templateFolder | Write-ProjectMessage

        if(-not (Test-Path $targetFolder)){ 
            New-Item -ItemType Directory $targetFolder | Out-Null
        }
        $targetFolder = Get-Item $targetFolder

        if(!(Test-FolderIsEmpty -folderPath $targetFolder)){
            $prompt = @(New-Object psobject -Property @{
                        Name = 'continuenotempty'
                        Text='Folder is not empty, continue generating??'
                        PromptAction = {
                            ConvertTo-Bool(Get-TextFromUser)
                        }})

            if(-not (Invoke-Prompts -prompts $prompt)['continuenotempty']){
                throw 'folder is not empty'
            }
        }

        $projType = $parameters['projtype']
        $templateFolder = (get-item(Join-Path -Path $global:riddlerpssettings.TemplateRoot -ChildPath $projType))
        if(-not (Test-Path $templateFolder)){
            throw ("Template folder not found at [{0}]" -f $templateFolder)
        }

        $files = Get-ChildItem $templateFolder -Recurse -File

        Push-Location | Out-Null
        Set-Location $targetFolder
        $files | ForEach-Object{
            $templateFile = (Get-Item $_.FullName)
            $relFolder = Get-RelativePath -from ($templateFile.Directory.FullName) -to $targetFolder
            $destFile = (Join-Path ($targetFolder.FullName) -ChildPath $templateFile.Name)

            Copy-Item -LiteralPath ($templateFile.FullName) -Destination $destFile
        }

        (ls $targetFolder).FullName | Write-ProjectMessage


        $totalSeconds = 2        
        if($parameters['addmvc']){
            $seconds = 0
            'Adding MVC' | Report-FakeProgress
        }
                
        if($parameters['addwebapi']){
            $seconds = 0
            'Adding Web API' | Report-FakeProgress
        }

        if($parameters['addwebforms']){
            $seconds = 0
            'Adding Web forms' | Report-FakeProgress
        }

        if($parameters['unittest']){
            $seconds = 0
            'Adding a unit test project' | Report-FakeProgress
        }

        Pop-Location | Out-Null

        "`nProject created successfully in $targetFolder" | Write-ProjectMessage
    }
}

function Test-FolderIsEmpty{
    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true)]
        $folderPath
    )
    process{
        if(-not (Test-Path $folderPath)){
            $msg = ("The folder does not exist [{0}]" -f $folderPath)
            throw $msg
        }

        # return true/false if its empty or not
        if((Get-ChildItem $folderPath)){
            $false
        }
        else{
            $true
        }
    }
}

#######################################################################
# Begin script
#######################################################################
$prompts = @(
        (New-Object psobject -Property @{
            Name = 'unittest'
            Text='Do you want to add a unit test project?'
            PromptAction = {
                # you can have a custom action for your prompt as well
                ConvertTo-Bool(Get-TextFromUser)
            }
        }),
        (New-Object psobject -Property @{
            Name='addmvc'
            Text='Do you want to add MVC?'
            Type='Optional'
            Default=$false
        }),
        (New-Object psobject -Property @{
            Name='addwebapi'
            Text='Do you want to add Web API?'
            Type='Optional'
            Default=$false
        }),
        (New-Object psobject -Property @{
            name='addwebforms'
            Text='Do you want to add webforms'
            Type='Optional'
            Default=$false
        })
        )
