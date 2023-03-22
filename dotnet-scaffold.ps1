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
        ShowProgressMessage -message 'Looking for model classes' -numChars 15
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