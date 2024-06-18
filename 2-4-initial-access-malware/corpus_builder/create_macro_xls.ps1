# Create a new COM object for Excel
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false  # Ensure Excel does not show its window
$excel.DisplayAlerts = $false  # Disable display alerts to prevent pop-up interruptions
$excel.Interactive = $false  # Run Excel in non-interactive mode

# Define the full path to the workbook
$workbookPath = "$(Get-Location)\template.xlsx"
Write-Host "Attempting to open workbook at path: $workbookPath"

# Try to open an existing workbook
try {
    $workbook = $excel.Workbooks.Open($workbookPath)
} catch {
    Write-Host "Failed to open the workbook. Check the file path and name. Error: $_.Exception.Message"
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    return
}

# Assuming access to the VBA project is already allowed in Excel settings
try {
    $excel.VBE.CommandBars.FindControl(1, 2578).Execute()
} catch {
    Write-Host "Could not adjust VBA project settings. Check Excel's trust center settings. Error: $_.Exception.Message"
}

# Add a new VBA module
$module = $workbook.VBProject.VBComponents.Add(1)  # 1 is vbext_ct_StdModule

# Import VBA code from a file
$macroCode = Get-Content "$(Get-Location)\macro.vbs" -Raw
$module.CodeModule.AddFromString($macroCode)

# Add the Workbook_Open event to ThisWorkbook to call GreetUser
# German Excel changes the name.
# English: replace DieseArbeitsmappe with ThisWorksheet
$thisWorkbook = $workbook.VBProject.VBComponents.Item("DieseArbeitsmappe")
$openEventCode = @"
Private Sub Workbook_Open()
    Call GreetUser
End Sub
"@
$thisWorkbook.CodeModule.AddFromString($openEventCode)

# Save the workbook as a macro-enabled workbook
$macroEnabledPath = "$(Get-Location)\new_workbook_3.xlsm"
$workbook.SaveAs($macroEnabledPath, 52)  # 52 stands for xlOpenXMLWorkbookMacroEnabled

# Clean up: close workbook and quit Excel
$workbook.Close($true)
$excel.Quit()

# Reset Excel properties for cleanup
$excel.DisplayAlerts = $true
$excel.Interactive = $true

# Release COM objects
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($module) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
