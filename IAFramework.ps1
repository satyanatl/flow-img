#$GlobalVar- Local variable to be replaced by global variables provided by SCOM team

Param(
    [Parameter(Mandatory = $true)]
    [string]$ci_name,
    [Parameter(Mandatory = $true)]
    [string]$issue_type,
    [Parameter(Mandatory = $true)]
    [int]$remediation_retry,
    [Parameter(Mandatory = $true)]
    $fqdn,
    [Parameter(Mandatory = $true)]
    $script_abs_path="D:\SOP\",
    [Parameter(Mandatory = $true)]
    $data_abs_path="D:\Temp\",
    [Parameter(Mandatory = $true)]
    $retry,
    [Parameter(Mandatory = $true)]
    $threshold = 22,
    [Parameter(Mandatory = $true)]
    $writeToFile = "false",
    [Parameter(Mandatory = $true)]
    $waitInSec = 10
)

$LogFilePath =  $data_abs_path + "\" + $ci_name +"_SOP_Log.txt"
$script_abs_path_prevalidation = $script_abs_path + "\Validator.ps1"
$script_abs_path_remediation = $script_abs_path + "\SOPRemediation.ps1"
$finalReply = ""
# Function to Write Output to Host/ Log to file(to be implemented later)
Function WriteLog{
    Param (
        [string]$log
    )
    write-Host $log -ForegroundColor Magenta 
    if($writeToFile -eq "true"){
        Add-Content $LogFilePath $log
    }
}
WriteLog "IAFramework.ps1 : Executing"
# Function to verify if VM is running low on Disk Space 
Function CallVarifier
{
    Param (
        [string]$fqdn,
        [string]$threshold
        )
        WriteLog "IAFramework.ps1 : Calling CallValidator.ps1"
        try{
        
            # Add Authentication to execute scripts on remote servers.
            # Need to create Runspace while connecting to remote servers.
            $result = Invoke-Expression "$script_abs_path_prevalidation $fqdn $threshold $writeToFile $LogFilePath"
        }
        catch{
            WriteLog "IAFramework.ps1 : Failed to execute CallValidator.ps1"
            $result = "An Error Occured, Please try again later."
        }
        Write-Output $result
}

# Function to perform CleanUp
Function CallSOPRemediation
{
 
    Param (
        [string]$fqdn,
        [string]$script_path_remediation,
        [string]$script_path_prevalidation
        )
        WriteLog "IAFramework.ps1 : Calling SOPRemediation.ps1"
        try{
            # Add Authentication to execute scripts on remote servers.
            # Need to create Runspace while connecting to remote servers.
            $result = Invoke-Expression "$script_path_remediation $fqdn $writeToFile $LogFilePath"
        }
        catch{
            WriteLog "IAFramework.ps1 : Failed to execute SOPRemediation.ps1"
            $result = "error"
        }
        Write-Output $result
}

# Cleanup Retry if Remediation didn't work
Function RetryRemediation{
Param (
    [string]$fqdn,
    [string]$script_path_remediation,
    [string]$script_path_prevalidation
)
$status = "false"

WriteLog "IAFramework.ps1 : RetryRemediation Started."
For ($retrySOP = 1; $retrySOP -le $remediation_retry; $retrySOP++){
    
    $logVal = "IAFramework.ps1 : Remediation Retry waiting for " + ($waitInSec) + " seconds"
    WriteLog $logVal
    Start-Sleep -s $waitInSec #Wait for few seconds(based on var value) before retrying.
    $logVal = "IAFramework.ps1 : Remediation Retry " + ($retrySOP)
    WriteLog $logVal

    $resultSOPRemediation1 = CallSOPRemediation -fqdn $fqdn -script_path_remediation $script_abs_path_remediation -script_path_prevalidation $script_abs_path_prevalidation
    if($resultSOPRemediation1 -eq "true"){
        $resultValidator1 = CallVarifier -fqdn $fqdn -threshold $threshold
        if($resultValidator1 -ne $null){
            if($resultValidator1 -eq "true"){
                $status = "true"
                WriteLog "IAFramework.ps1 : Remediation successful after retry."
            }
        }
    }
}
WriteLog "IAFramework.ps1 : RetryRemediation Completed."
$status
}

# Main Function to Monitor all other functions
function StartProcessing{
    $counterR = 1
    $counterV = 1
    $counterV1 = 1
    $flagSOP = "false"
    $flagVerifier = "false"
    $flagValidator = "false"

    if($writeToFile -eq "true"){
        New-item $LogFilePath -Force    
    }
    
    # Call Validator to ensure if Disk Space is below Threshold
   
For ($counterV1=1; $counterV1 -le $retry){
    if($flagVerifier = "false"){
    $resultVerifier = CallVarifier -fqdn $fqdn -threshold $threshold #"40"
    if($resultVerifier -eq "false"){
        $flagVerifier = "true"
        for ($counterR=1; $counterR -le $retry){
            if($flagSOP -eq "false"){
                $counterR = $counterR + 1
                $resultSOPRemediation = CallSOPRemediation -fqdn $fqdn -script_path_remediation $script_abs_path_remediation -script_path_prevalidation $script_abs_path_prevalidation
                if($resultSOPRemediation -eq "true"){
                    $flagSOP = $resultSOPRemediation
                    for ($counterV=1; $counterV -le $retry){
                        if($flagValidator -eq "false"){
                            $counterV = $counterV + 1
                            $resultValidator = CallVarifier -fqdn $fqdn -threshold $threshold
                    
                            if($resultValidator -ne $null){
                                $flagValidator = "true"
                                if($resultValidator -eq "true"){
                                    WriteLog "IAFramework.ps1 : Execution completed"
                                }
                                else{
                                    # Retry Remediation
                                    
                                    $resultSOPRemediationRetry = RetryRemediation -fqdn $fqdn -script_path_remediation $script_abs_path_remediation -script_path_prevalidation $script_abs_path_prevalidation
                                    if($resultSOPRemediationRetry -eq "true"){
                                        $finalReply = "IAFramework.ps1 : Execution completed. Remediation Successful."
                                        WriteLog $finalReply
                                    }
                                    else{
                                        $finalReply = "IAFramework.ps1 : Execution completed, Manual Remeditiation required."
                                        WriteLog $finalReply
                                    }
                                    
                                }
                                WriteLog $resultValidator
                                Write-output $finalReply #$resultValidator
                            }
                            else{
                                if($counterV -gt $retry){
                                    $flagValidator = "true"
                                    exit
                                }
                                WriteLog "IAFramework.ps1 : Execution completed"
                                Write-output $resultValidator
                            }
                            if($flagValidator -eq "true"){
                                exit
                            }
                        }
                    }
                    
                }
                else{
                    if($counterR -gt $retry){
                        WriteLog "IAFramework.ps1 : Error occured! Retry Later."
                        WriteLog "false"
                        return "false"
                        $flagSOP = "true"
                        exit
                    }
                }
            } #end if
            #exit    
        }
    }
    else{
        $counterV1 = $counterV1 + 1
        if($resultVerifier -eq "true"){
            $flagVerifier = "true"
            $finalReply = "IAFramework.ps1 : Execution completed, No Remediation Required."
            WriteLog $finalReply
            WriteLog "true"
            return $finalReply
        }
        else{
            $finalReply = "IAFramework.ps1 : Error occured! Retry Later."
            WriteLog $finalReply
            WriteLog "error"
            $finalReply
        }
    }  
}  
} #end ForLoop
} #end StartProcessing


# Call Function to start Remediation Process
StartProcessing
#Write-Output "Remediation Performed Successfully"