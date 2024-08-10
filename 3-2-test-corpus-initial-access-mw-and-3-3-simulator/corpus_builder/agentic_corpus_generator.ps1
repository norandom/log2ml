param (
    [int]$c = 1,  # Number of workbooks to generate
    [string]$apiKey = "",  # API key for OpenAI
    [string]$logFile = "agent_log.txt"  # Log file path
)

function Write-AgentLog {
    param ([string]$message)
    $logMessage = "$(Get-Date) - $message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Host $logMessage
}

function Get-RandomVBACode {
    param ([string]$apiKey)
    
    $prompt = @"
Generate a VBA macro named 'Sub GreetUser()' that does the following:
1. Creates sample data in the active worksheet (e.g., a table with headers and some rows of data)
2. Performs an operation on this data (e.g., creating a pivot table, chart, or applying formatting)
3. Includes error handling
4. Is well-commented
5. Does not rely on any existing data in the spreadsheet

Provide ONLY the VBA code, without any explanations or markdown code block markers.
"@

    $body = @{
        model = "gpt-4"
        messages = @(
            @{role = "system"; content = "You are an expert VBA developer. Provide only the requested VBA code without any explanations or markdown."}
            @{role = "user"; content = $prompt}
        )
        max_tokens = 1000
        temperature = 0.7
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri "https://api.openai.com/v1/chat/completions" -Method Post -Headers @{
            "Authorization" = "Bearer $apiKey"
            "Content-Type" = "application/json"
        } -Body $body
        
        $code = $response.choices[0].message.content.Trim()
        
        # Remove any text before Sub GreetUser() and after End Sub
        $code = $code -replace "(?s).*?(Sub\s+GreetUser\s*\(\s*\))", '$1'
        $code = $code -replace "(?s)(End Sub).*", '$1'
        
        # Remove any ``` or ```vba markers
        $code = $code -replace '```vba?', ''
        
        # Ensure the code starts with Sub GreetUser() and ends with End Sub
        if (-not ($code -cmatch "^Sub\s+GreetUser\s*\(\s*\)")) {
            $code = "Sub GreetUser()`n" + $code
        }
        if (-not ($code -cmatch "End Sub\s*$")) {
            $code += "`nEnd Sub"
        }
        
        return $code.Trim() + "`n"
    }
    catch {
        Write-AgentLog "Error in Get-RandomVBACode: $_"
        return $null
    }
}

Write-AgentLog "Script started"

try {
    Write-AgentLog "Creating Excel COM object"
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    Write-AgentLog "Excel COM object created successfully"

    $templatePath = "$(Get-Location)\template.xlsx"
    Write-AgentLog "Using template: $templatePath"

    for ($i = 1; $i -le $c; $i++) {
        Write-AgentLog "Processing workbook $i of $c"
        
        try {
            $workbook = $excel.Workbooks.Open($templatePath)
            Write-AgentLog "Template opened successfully"

            $randomVBACode = Get-RandomVBACode -apiKey $apiKey
            if ($null -eq $randomVBACode) {
                Write-AgentLog "Failed to generate VBA code. Skipping workbook $i"
                continue
            }

            Write-AgentLog "VBA code generated successfully"

            $module = $workbook.VBProject.VBComponents.Add(1)
            $module.CodeModule.AddFromString($randomVBACode)
            Write-AgentLog "VBA code added to workbook"

            $newWorkbookPath = "$(Get-Location)\agentic_workbook_$($i.ToString('D2')).xlsm"
            $workbook.SaveAs($newWorkbookPath, 52)
            Write-AgentLog "Workbook saved: $newWorkbookPath"

            $workbook.Close($false)
            Write-AgentLog "Workbook closed"
        }
        catch {
            Write-AgentLog "Error processing workbook $i`: $_"
        }
    }
}
catch {
    Write-AgentLog "Critical error: $_"
}
finally {
    if ($excel) {
        $excel.Quit()
        Write-AgentLog "Excel application closed"
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
        Write-AgentLog "Excel COM object released"
    }
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-AgentLog "Script completed"
}
#
