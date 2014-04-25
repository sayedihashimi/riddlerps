

#riddler ps module needs to be loaded before executing this

function Show-RiddlerPSHelp{
    [cmdletbinding()]
    param()
    process{

        $prompts = @(
            New-Object psobject -Property @{
                Name='action'
                Text="`r`nHi, I am the Riddler. How can I help?"
                Options= [ordered]@{
                    'Type'='PickOne'
                    'what-is'='What is RiddlerPS?'
                    'show-ex'='Show me how to use RidderPS'
                    'show-docs'='Take me to the docs!'
                    'report-issue'='Report an issue'
                    'quit'='Quit'
                }
            }
        )        
        
        $continueLoop = $true
        while($continueLoop){
            $promptResult = Invoke-Prompts $prompts 
            # execute the result
            switch ($promptResult['action']){
                'what-is' {what-is}
                'show-ex' {show-examples}
                'show-docs' { start 'https://github.com/sayedihashimi/riddlerps' }
                'report-issue' { start 'https://github.com/sayedihashimi/riddlerps/issues' }            
                'quit' { 'Goodbye'; $continueLoop = $false  }
                default{ throw  ('Unknown choice: [{0}]' -f  $selectedOption) }
            }
        }        
    }
}

function what-is{
    [cmdletbinding()]
    param()
    process{
        'RiddlerPS is a PowerShell module that simplifies user interaction in PowerShell.' | Write-Example
    }
}

function show-examples{
    [cmdletbinding()]
    param()
    process{
        $prompts = @(
            New-Object psobject -Property @{
                Name='action'
                Text="`r`nWhat kind of example are you looking for?"
                Options=[ordered]@{
                    'Type'='PickOne'
                    'question'='How can I ask the user a question?'
                    'pickone'='How can I show a list where one value can be selected?'
                    'pickmany'='How can I show a list where more than one value can be selected'
                    'multiquestions'='How can I ask more than one question?'
                    'customprompt'='How to handle custom actions'
                    'goback'='Go back'
                    'quit'='Quit'
                }
            })

        $continueLoop = $true
        while($continueLoop){
            $promptResult = Invoke-Prompts $prompts

            switch($promptResult['action']){
                'question' { Show-Question }
                'pickone' {Show-PickOne}
                'pickmany' {Show-PickMany}
                'multiquestions' { Show-MultiQuestions  }
                'customprompt' {Show-CustomPromptAction}
                'goback' { $continueLoop = $false}
                'quit' { exit }
            }
        }
    }
}

function Write-Example{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $message
    )
    process{
        '----------------------------------------------------' | Write-Host -ForegroundColor Green
        $message | Write-Host
        '----------------------------------------------------' | Write-Host -ForegroundColor Green
    }
}

function Show-Question{
    [cmdletbinding()]
    param()
    process{
        $str = @'
        $prompt = New-Object psobject -Property @{                 
                    Name='action'
                    Text='What is your name?'
        }

        $promptResult = Invoke-Prompts $prompt
'@
        
        'Asking the user a question is simple. Here is how you do it.' | Write-Host
        $str | Write-Example

        Invoke-Expression $str
        "Your reply: '{0}'`r`n" -f $promptResult['action'] | Write-Host
    }
}

function Show-PickOne{
    [cmdletbinding()]
    param()
    process{
        'To show a list of options where the user can select one value you will use the
PickOne method. Let''s try it' | Write-Host
        $str = @'
        $prompt = New-Object psobject -Property @{                 
            Name='action'
            Text='What type of project do you want to create?'
            Options=[ordered]@{
                'Type'='PickOne'
                'mvc'='ASP.NET MVC'
                'webforms'='ASP.NET Web Forms'
                'webapi'='ASP.NET Web API'
                'goback'='Go back'
                'quit' = 'Quit'
            }
        }

        $promptResult = Invoke-Prompts $prompt
'@
        $str | Write-Example

        Invoke-Expression $str

       "Your reply: '{0}'`r`n" -f $promptResult['action'] | Write-Host
    }
}

function Show-PickMany{
    [cmdletbinding()]
    param()
    process{
        'To show a list of options where the user can select more than one value 
you will use the PickMany method. With PickMany the result may have multiple results.
The respons will be returned as a hashtable with all selected values
set to true. All other values will be omitted from the result.' | Write-Host
        $str = @'
        $prompt = New-Object psobject -Property @{                 
            Name='action'
            Text='Pick the frameworks you would like to include in your poject?'
            Options=[ordered]@{
                'Type'='PickMany'
                'mvc'='ASP.NET MVC'
                'webforms'='ASP.NET Web Forms'
                'webapi'='ASP.NET Web API'
            }
        }

        $promptResult = Invoke-Prompts $prompt
'@
        $str | Write-Example

        Invoke-Expression $str
        
       "Your reply:" -f $promptResult | Write-Host
       $promptResult
       "`r`n" | Write-Host
    }
}

function Show-MultiQuestions{
    [cmdletbinding()]
    param()
    process{

    'When asking more than one question you can supply a list of prompts.
I will take care of prompting the user and returning all values back to you
in a hashtable. Selected values will be incldued. Let''s see this in action.' | Write-Host

    $str =
@'
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
        }))

        $promptResult = Invoke-Prompts $prompts

'@
        $str | Write-Example
        Invoke-Expression $str
        "Your reply:" -f $promptResult | Write-Host
           $promptResult
           "`r`n" | Write-Host
    }
}

function Show-CustomPromptAction{
    [cmdletbinding()]
    param()
    process{
        'show custom prompt action here'
    }
}

Show-RiddlerPSHelp


