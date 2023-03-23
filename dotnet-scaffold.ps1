#riddler ps module needs to be loaded before executing this
function StartDotnetScaffold{
    [cmdletbinding()]
    param()
    process{
        $prompts = @(
            New-PromptObject `
            -promptType PickOne `
            -text "`r`nSelect an action below" `
            -options ([ordered]@{
                'api'='API'
                'view'='View'
                'identity'='Identity'
                'layout'='Layout'
            })
        )

        $promptResult = Invoke-Prompts $prompts -IndentLevel 0
        switch($promptResult['userprompt']){
            'api' {dotnet-scaffold-api}
            'view' {dotnet-scaffold-view}
            'identity' {dotnet-scaffold-identity}
            'layout' {dotnet-scaffold-layout}
            default{ throw  ('Unknown choice: [{0}]' -f  $selectedOption) }
        }
    }
}

function dotnet-scaffold-api{
    [cmdletbinding()]
    param()
    process{
        $prompts = @(
            New-PromptObject `
            -promptType PickOne `
            -text "`r`nWhat type of API do you want to generate?" `
            -options ([ordered]@{
                'minimal'='Minimal API endpoints'
                'controller'='Controller based'
            })
        )
        $promptResult = Invoke-Prompts $prompts -IndentLevel 0

        switch($promptResult['userprompt']){
            'minimal' {dotnet-scaffold-api-minimal}
            'controller' {dotnet-scaffold-api-controller}
        }
    }
}
function dotnet-scaffold-api-minimal{
    [cmdletbinding()]
    param()
    process{
        'inside minimal api' | Write-Output
    }
}
function dotnet-scaffold-api-controller{
    [cmdletbinding()]
    param()
    process{
        $prompts = @(
            new-PromptObject `
            -promptType PickOne `
            -text "`r`nWhich controller scaffolder do you want to invoke" `
            -options ([ordered]@{
                'empty' = 'Empty controller'
                'readwrite' = 'With blank read/write actions'
                'withef' = 'With actions, using Entity Framework'
            })
        )

        $promptResult = Invoke-Prompts $prompts -IndentLevel 0

        switch($promptResult['userprompt']){
            'empty' {dotnet-scaffold-api-controller-empty}
            'readwrite' {dotnet-scaffold-api-controller-readwrite}
            'withef' {dotnet-scaffold-api-controller-ef}
            default{ throw  ('Unknown choice: [{0}]' -f  $promptResult['userprompt']) }
        }
    }
}
function dotnet-scaffold-api-controller-empty{
    [cmdletbinding()]
    param()
    process{
        $prompt = New-PromptObject -text 'Name of the controller?'
        $promptResult = Invoke-Prompts $prompt -IndentLevel 0

        'Generating {0}.cs in folder {1}' -f $promptResult['userprompt'],$pwd | Write-Output
        ShowProgressMessage
        'Succeeded without any issues' | Write-Output
        "`r`nRun the command below to get the same result without console interactivity: `r`n`tdotnet scaffold api controller empty {0}" -f $promptResult['userprompt'] | Write-output
    }
}
function dotnet-scaffold-api-controller-readwrite{
    [cmdletbinding()]
    param()
    process{
        $prompt = New-PromptObject -text 'Name of the controller?'
        $promptResult = Invoke-Prompts $prompt -IndentLevel 0

        'Generating read/write controller {0}.cs in folder {1}' -f $promptResult['userprompt'],$pwd | Write-Output
        ShowProgressMessage
        'Succeeded without any issues' | Write-Output
        "`r`nRun this command to get the same result without interactivity: `r`n`tdotnet scaffold api controller readwrite {0}" -f $promptResult['userprompt'] | Write-output
    }
}
function dotnet-scaffold-api-controller-ef{
    [cmdletbinding()]
    param()
    process{
        # 1: get the model class to use
        $prompt = New-PromptObject -text 'What model class do you want to generate the content from? (Partial name is OK)'
        $promptResult = Invoke-Prompts $prompt -IndentLevel 0
        $modelClassPartialName = $promptResult['userprompt']
        ShowProgressMessage -message 'Looking for classes' -numChars 15

        [string[]]$fakeNames = createDummyClassNamesFrom -partialName $modelClassPartialName
        $prompt = New-PromptObject -name 'action' -text 'Select the model class' `
                    -promptType PickOne `
                    -options ([ordered]@{
                                '0'=$fakeNames[0]
                                '1'=$fakeNames[1]
                                '2'=$fakeNames[2]
                                '3'=$fakeNames[3]
                                '4' = $fakeNames[4]
                            })
        $promptResult = Invoke-Prompts $prompt -IndentLevel 0
        $selectedModelClass = $fakeNames[$promptResult['action']]
        'Class selected: "{0}"' -f $selectedModelClass

        # $allOptionsSelected = [ordered]@{ 'Model class'=$selectedModelClass}

        # 2: get the name of the DbContext, may be existing or create new
        $prompt = New-PromptObject -name 'createDbContext' -text 'Do you have a DbContext class that you want to use?' `
                            -promptType PickOne `
                            -options ([ordered]@{
                                'select existing'='yes'
                                'create new'='no, create a new DbContext'
                            })
        $promptResult = Invoke-Prompts $prompt -IndentLevel 0

        $createDbContextOrCreateNew = $promptResult['createDbContext']
        # $allOptionsSelected['Select existing DbContext or create a new one?'] = $createDbContextOrCreateNew

        [string]$selectedDbProvider = ''
        [string]$dbContextClassName = ''
        switch($promptResult['createDbContext']){
            'select existing' {
                ShowProgressMessage -message 'Looking for DbContext classes' -numChars 15
                $fakeDbContextClasses = @('AdminDbContext','ContactsDbContext','HrDbContext','SalesDbContext')
                $prompt = New-PromptObject -name 'selectedDbContext' -text 'Select the DbContext class to use' `
                            -promptType PickOne `
                            -options ([ordered]@{
                                        $fakeDbContextClasses[0]=$fakeDbContextClasses[0]
                                        $fakeDbContextClasses[1]=$fakeDbContextClasses[1]
                                        $fakeDbContextClasses[2]=$fakeDbContextClasses[2]
                                        $fakeDbContextClasses[3]=$fakeDbContextClasses[3]
                                    })

                $promptResult = Invoke-Prompts $prompt -IndentLevel 0
                $dbContextClassName = $promptResult['selectedDbContext']
            }
            'create new' {
                $dbContextClassName = PromptForNameWithSuffix -message 'Name for the new DbContext class?' -suffix 'Context' -noSuffixConfirmMessage 'Select the name of the context class to create'
                # get the dbprovider
                $selectedDbProvider = PromptForDbProvider
            }
            default{ throw  ('Unknown choice: [{0}]' -f  $promptResult['createDbContext']) }
        }
        # $allOptionsSelected['DbContext class name'] = $dbContextClassName
        'Selected DbContextClassName: {0}' -f $dbContextClassName | Write-Output

        # 3: get the name of the Controller, may be existing or create new
        $controllerName = PromptForNameWithSuffix -message 'Controller name?' -suffix 'Controller' -noSuffixConfirmMessage 'Select the name of the Controller class to create'

        $allOptionsSelected = [ordered]@{
            'Model class' = $selectedModelClass
            'Select existing DbContext or create a new one?' = $createDbContextOrCreateNew
            'DbContext class name' = $dbContextClassName
            'Controller class name' = $controllerName
        }

        'The settings below have been provided for scaffolding.' | Write-Output
        $allOptionsSelected | Format-Table -AutoSize
        $confirmPrompt = New-PromptObject -name 'confirmContinue' -text 'Generate the files now, with these settings?' -promptType Bool
        $confirmPromptResult = Invoke-Prompts $confirmPrompt -IndentLevel 0

        switch($confirmPromptResult['confirmContinue']){
            'yes' {
                $files = @(
                    GetFileObject -filename "YourProject.csproj" -newFile $false
                    GetFileObject -filename ("Data/{0}.cs" -f $dbContextClassName) -newFile $true
                    GetFileObject -filename ("Controller/{0}.cs" -f $controllerName) -newFile $true
                    GetFileObject -filename "Program.cs" -newFile $false
                    GetFileObject -filename "Properties/serviceDependencies.json"  -newFile $true
                    GetFileObject -filename "Properties/serviceDependencies.local.json"  -newFile $true
                    GetFileObject -filename "appSettings.json"  -newFile $true
                )

                PrintFileMessages -fileObject $files

                # dotnet scaffold api controller ef model  newdbcontext ContactsDbContext
                $msg = "`r`nRun the command below to get the same result without console interactivity: `r`n`tdotnet scaffold api controller ef model " -f $selectedModelClass
                if($createDbContextOrCreateNew -eq 'create new'){
                    $msg += ('dbprovider {0}' -f $selectedDbProvider)
                    $msg += (' newdbcontext {0}' -f $dbContextClassName)
                }
                else{
                    $msg += ('dbcontext {0}' -f $dbContextClassName)
                }
                $msg += (' controllerClassName {0}' -f $controllerName)
                '' | Write-Output
                'Succeeded without any issues' | Write-Host -ForegroundColor Green
                $msg | Write-Output
            }
            'no' {
                'go back somehow'
            }
            default{ throw  ('Unknown choice: [{0}]' -f  $promptResult['confirmContinue']) }
        }
    }
}
function PromptForDbProvider{
    [cmdletbinding()]
    param()
    process{
    $prompt = New-PromptObject -name 'selectedDbProvider' -text 'Select the database provider' `
                -promptType PickOne `
                -options ([ordered]@{
                            'sqlserver'='SQL Server'
                            'sqlite'='SQLite'
                            'postgresql'='PostgreSQL'
                            'azurecosmos'='Azure Cosmos DB'
                        })

    $promptResult = Invoke-Prompts $prompt -IndentLevel 0
    # return the selected value
    $promptResult['selectedDbProvider']
    }
}
function GetFileObject{
    [cmdletbinding()]
    param(
        [string]$filename,
        [bool]$newFile = $false
    )
    process{
        [string]$message = "Modifying "
        if($newFile){
            $message = "Creating "
        }
        new-object psobject -Property @{
            Filename = $filename
            Message = $message
        }
    }
}
$random = new-object random
function PrintFileMessages{
    [cmdletbinding()]
    param(
        $fileObject
    )
    process{
        ShowProgressMessage -message "Getting ready" -numChars 10 -waitTimeMilliseconds 100
        foreach($file in $fileObject){
            $numStars = $random.Next(30)
            # '{0}{1} ' -f $file.message, $file.filename | Write-Host -NoNewline
            ShowProgressMessage -message ('{0}{1} ' -f $file.message, $file.filename) -numChars $numStars -waitTimeMilliseconds 2
        }
    }
}

function PromptForNameWithSuffix{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$message,

        [Parameter(Mandatory=$true,Position=1)]
        [string]$suffix=1,

        [Parameter(Mandatory=$true,Position=2)]
        [string]$noSuffixConfirmMessage
    )
    process{
        $prompt = New-PromptObject -text $message
        $promptResult = Invoke-Prompts $prompt -IndentLevel 0
        $dbContextClassName = $promptResult['userprompt']

        if(-not ($dbContextClassName.EndsWith($suffix))){
            # see if the user wants to suffix it with Context
            $prompt = New-PromptObject -name 'providedName' -text 'Select the name of the context class to create' `
                    -promptType PickOne `
                    -options ([ordered]@{
                                ('{0}' -f $dbContextClassName)=('{0}' -f $dbContextClassName)
                                ('{0}{1}' -f $dbContextClassName, $suffix)=('{0}{1}' -f $dbContextClassName, $suffix)
                            })
            $promptResult = Invoke-Prompts $prompt -IndentLevel 0
            $dbContextClassName = $promptResult['providedName']
        }

        # return the selected value
        $dbContextClassName
    }
}
function createDummyClassNamesFrom{
    [cmdletbinding()]
    param(
        [string]$partialName
    )
    process{
        # if the # of elements returned changes, we need to update the callers to this
        @(('{0}' -f $partialName),
          ('{0}Factory' -f $partialName),
          ('{0}Manager' -f $partialName),
          ('{0}Model' -f $partialName),
          ('{0}ViewModel' -f $partialName)
        )
    }
}
function dotnet-scaffold-view{
    [cmdletbinding()]
    param()
    process{
        'inside view' | write-output
    }
}
function dotnet-scaffold-identity{
    [cmdletbinding()]
    param()
    process{
        'inside identity' | write-output
    }
}
function dotnet-scaffold-layout{
    [cmdletbinding()]
    param()
    process{
        'inside layout' | write-output
    }
}
#********** **********
function ShowProgressMessage{
    [cmdletbinding()]
    param(
        [string]$message = "Working ",
        [int]$numCharsToPrint = 60,
        [int]$waitTimeMilliseconds = 100
    )
    process{
        "{0} " -f $message | Write-Host -NoNewline
        for($i = 0;$i -lt $numCharsToPrint;$i++){
            '*' | Write-Host -NoNewline
            Start-Sleep -Milliseconds $waitTimeMilliseconds
        }
        # to get the cursor on a new line for future output
        '' | Write-Host
    }
}

StartDotnetScaffold