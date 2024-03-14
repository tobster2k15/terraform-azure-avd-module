function Write-Log {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        # note: can't use variable named '$Error': https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/AvoidAssignmentToAutomaticVariable.md
        [Parameter(Mandatory = $false)]
        [switch]$Err,

        [Parameter(Mandatory = $false)]
        [System.Exception]$Ex
    )
     
    try {
        $DateTime = Get-Date -Format "MM-dd-yy HH:mm:ss:fff"
        $Invocation = "$($MyInvocation.MyCommand.Source):$($MyInvocation.ScriptLineNumber)"
        $Level = "[INFORMATION]"

        if ($Err) {
            $Level = "[ERROR]"
        }

        if($Ex)
        {
            $ExMessage = Ex.Exception.Message
            $ExceptionStacktrace = Ex.Exception.StackTrace
        }
        
$Entry = @"
Timestamp: $DateTime
Event: $Level
Line: $Invocation     
Message: $Message
Exception: $ExMessage 
StackTrace: $ExceptionStacktrace
------------------------------------------------------
"@

        Add-Content -Value $Entry -Path "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\ManualDscStorageScriptsLog.log"
    }
    catch {
        throw [System.Exception]::new("Some error occurred while writing to log file with message: $Message", $PSItem.Exception)
    }
}

