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

        $promptResult = Invoke-Prompts $prompts
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
        'inside api' | write-output
        $prompts = @(
            New-PromptObject `
            -promptType PickOne `
            -text "`r`nWhat type of API do you want to generate?" `
            -options ([ordered]@{
                'minimal'='Minimal API endpoints'
                'controller'='Controller based'
            })
        )
        $promptResult = Invoke-Prompts $prompts

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

        $promptResult = Invoke-Prompts $prompts

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
        $promptResult = Invoke-Prompts $prompt

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
        $promptResult = Invoke-Prompts $prompt

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
        $prompt = New-PromptObject -text 'What model class do you want to generte the content from? (Partial name is OK)'
        $promptResult = Invoke-Prompts $prompt
        $modelClassPartialName = $promptResult['userprompt']
        ShowProgressMessage -message 'Looking for classes' -numChars 15
        # $prompt = New-PromptObject -text 'Select the model class'
        # returns 5 elements
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
        $promptResult = Invoke-Prompts $prompt
        'Class selected: "{0}"' -f $fakeNames[$promptResult['action']]

        $prompt = New-PromptObject -name 'createDbContext' -text 'Do you have a DbContext class that you want to use?' `
                            -promptType PickOne `
                            -options ([ordered]@{
                                'yes'='yes'
                                'no'='no, create a new DbContext'
                            })
        $promptResult = Invoke-Prompts $prompt

        switch($promptResult['createDbContext']){
            'yes' {dotnet-scaffold-api-controller-ef-existing-db-context}
            'no' {dotnet-scaffold-api-controller-ef-new-db-context}
            default{ throw  ('Unknown choice: [{0}]' -f  $promptResult['createDbContext']) }
        }
    }
}
function dotnet-scaffold-api-controller-ef-existing-db-context{
    [cmdletbinding()]
    param()
    process{
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

        $promptResult = Invoke-Prompts $prompt
    }
}
function dotnet-scaffold-api-controller-ef-new-db-context{
    [cmdletbinding()]
    param()
    process{
        $prompt = New-PromptObject -text 'Name for the new DbContext class?'
        $promptResult = Invoke-Prompts $prompt
        $dbContextClassName = $promptResult['userprompt']

        if(-not ($dbContextClassName.EndsWith('Context'))){
            # see if the user wants to suffix it with Context
            $prompt = New-PromptObject -name 'selectContextClassName' -text 'Select the name of the context class to create' `
                    -promptType PickOne `
                    -options ([ordered]@{
                                ('{0}' -f $dbContextClassName)=('{0}' -f $dbContextClassName)
                                ('{0}Context' -f $dbContextClassName)=('{0}Context' -f $dbContextClassName)
                            })
            $promptResult = Invoke-Prompts $prompt
            $dbContextClassName = $promptResult['selectContextClassName']
        }

        'Selected DbContextClassName: {0}' -f $dbContextClassName | Write-Output
    }
}
function dotnet-scaffold-api-controller-ef-get-controller-name{
    [cmdletbinding()]
    param()
    process{

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