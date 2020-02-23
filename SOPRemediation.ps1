 Param (
    [Parameter(Mandatory = $true)]
    [string]$fqdn,
    [Parameter(Mandatory = $true)]
    [string]$writeToFile,
    [Parameter(Mandatory = $true)]
    [string]$LogFilePath
    )

	$objShell = New-Object -ComObject Shell.Application
	$objFolder = $objShell.Namespace(0xA)
	$temp = get-ChildItem "env:\TEMP"
	$temp2 = $temp.Value
	$swtools = "c:\SWTOOLS\"
	$WinTemp = "c:\Windows\Temp\*"
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

Try{
    # Remove files located in "c:\SWTOOLS\"
	WriteLog "Clearing Generic folder"
	#Remove-Item -Recurse  "$swtools\*" -Force -Verbose

# Remove temp files located in "C:\Users\USERNAME\AppData\Local\Temp"
	WriteLog "Removing Junk files in $temp2."
	Remove-Item -Recurse  "$temp2\*" -Force -Verbose

#	Empty Recycle Bin # http://demonictalkingskull.com/2010/06/empty-users-recycle-bin-with-powershell-and-gpo/
	WriteLog "Emptying Recycle Bin."
	$objFolder.items() | %{ remove-item $_.path -Recurse -Confirm:$false}
	
# Remove Windows Temp Directory 
	WriteLog "Removing Junk files in $WinTemp."
	#Remove-Item -Recurse $WinTemp -Force
	
# Running Disk Clean up Tool 
#	WriteLog "Finally now , Running Windows disk Clean up Tool"
#	cleanmgr /sagerun:1 | out-Null 
#	
#	$([char]7)
#	Sleep 1 
#	$([char]7)
#	Sleep 1 	
	
#	WriteLog "I finished the cleanup task,Bye Bye " 
##### End of the Script ##### ad

#Write-Output $fqdn"|"$script_abs_path"|"$script_abs_path_prevalidation
Write-Output "true"
}
catch
{
    Write-Output "true"
}


