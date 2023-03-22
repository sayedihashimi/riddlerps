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

        'Selection: {0}' -f $promptResult['userprompt']  | Write-output
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
            default{ throw  ('Unknown choice: [{0}]' -f  $selectedOption) }
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
        '  working ........................' | Write-output
        'Succeeded without any issues' | Write-Output
    }
}
function dotnet-scaffold-api-controller-readwrite{
    [cmdletbinding()]
    param()
    process{
        $prompt = New-PromptObject -text 'Name of the controller?'
        $promptResult = Invoke-Prompts $prompt

        'Generating read/write controller {0}.cs in folder {1}' -f $promptResult['userprompt'],$pwd | Write-Output
        '  working ........................' | Write-output
        'Succeeded without any issues' | Write-Output
    }
}
function dotnet-scaffold-api-controller-ef{
    [cmdletbinding()]
    param()
    process{

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
}function dotnet-scaffold-layout{
    [cmdletbinding()]
    param()
    process{
        'inside layout' | write-output
    }
}

StartDotnetScaffold