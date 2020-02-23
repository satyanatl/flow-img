 Param (
    [Parameter(Mandatory = $true)]
    [string]$fqdn,
    [Parameter(Mandatory = $true)]
    [string]$Threshold,
    [Parameter(Mandatory = $true)]
    [string]$writeToFile,
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath
)

$global:thresholdInGB = 0
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

WriteLog "Validator.ps1 : Executing"
Function GetDiskSpace
{
	Param(
        [string]$svr
    )

    $disk = ([wmi]"\\$svr\root\cimv2:Win32_logicalDisk.DeviceID='c:'")
    #"Remotecomputer C: has {0:#.0} GB free of {1:#.0} GB Total" -f ($disk.FreeSpace/1GB),($disk.Size/1GB) | write-output
    $totalDiskSpace = [math]::Round(($disk.Size/1GB),2)
    $totalFreeSpace = [math]::Round(($disk.FreeSpace/1GB),2)
    $global:thresholdInGB = $totalDiskSpace * ($Threshold/100)

    return $totalFreeSpace
}
Try{
    $diskSpace = GetDiskSpace -svr $fqdn
    if ($diskSpace -ge $global:thresholdInGB){
        # Disk space within threshold limit
        WriteLog "Validator.ps1 : Execution completed"
        return "true"
    }
    else{
        # Disk space not within threshold limit
        WriteLog "Validator.ps1 :  Execution completed"
        return "false"
    }
    #Write-Host $diskSpace
}
Catch{
    WriteLog "Validator.ps1 : Execution completed"
    return "Error"
}