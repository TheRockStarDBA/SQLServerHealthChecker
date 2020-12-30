Function Global:Write-LogToJSON {
    Param (
      
        [Parameter(mandatory = $true)]
        [string] $Msg,
      
        [Parameter(mandatory = $false)]
        [string] $LogFile,
      
        [Parameter(mandatory = $false)] 
        [string] $LogLevel = "INFO",
      
        [Parameter(mandatory = $false)]
        [hashtable] $ExtraArgs
    )
    # Msg is the only mandatory parameter.
    # By default LogLevel is INFO. 
    # If you don't pass a LogFile it will write to STDOUT only.
    # All extra parameters can be passed as a hash table.

    if ($null -eq $Msg) {
        Write-Output "-Msg parameter is mandatory."
        exit 1
    }

    #$tmpArray = @{Msg="$Msg"} 
    $tmpArray = @{} 
    $dt = Get-Date -Format "o"
    $tmpArray | Add-Member -NotePropertyName timestamp -NotePropertyValue $dt 
    $tmpArray | Add-Member -NotePropertyName LogLevel -NotePropertyValue $LogLevel
    $tmpArray | Add-Member -NotePropertyName Msg -NotePropertyValue $Msg
    if ($null -ne $ExtraArgs -and $ExtraArgs.count -gt 0) {
        ForEach ($key in $ExtraArgs.Keys) {
            $tmpArray | Add-Member -NotePropertyName $key -NotePropertyValue $ExtraArgs[$key]
        }
    }

    # If LogFile is specified then write to just $FilePath .. else write to Console ..   
    $msg = $tmpArray | ConvertTo-Json -Compress -Depth 50 | ForEach-Object { [regex]::Unescape($_) }   
    
    if ($FilePath) {
        $msg | out-file -FilePath $FilePath -Encoding utf8 -Append
    }
    else {
        $msg
    }
}
function global:Rotate-LogFile {
    param(
        [string]$FileName,
        [int] $MaxLines = 10000,
        [int] $Keep = 5,
        [switch] $Help
    )
    try {
        if ($Help) {
            $FuncName = $MyInvocation.MyCommand
            Write-output "$FuncName -FileName FileName [-MaxLines MaxLines] [-Keep Keep] [-Help]"
            Write-output "  -FileName FileName: (mandatory) Full path with File name to be rotated. If it is a valid filepath and filename, it will be created if it does not exists."
            Write-output "  -MaxLines MaxLines: (optional) Default 10000. Maximum no of lines before rotating the log."
            Write-output "  -Keep Keep: (optional) Default 5. Maximum numbers of logs to keep."
            Write-output "  -Help : (optional) Prints help message."
            return 
        } 
        if (!(Test-Path $FileName) -or (get-item "$FileName").PSIsContainer) {
            New-Item -path $FilePath  -ItemType File -Force  -ErrorVariable resultOut -ErrorAction SilentlyContinue
            if(!$resultOut) {
                Write-Output "$fileName is created successfully"

            } else {

            return @{"ExitCode" = $false; "ExitMsg" = "File or location $FileName does not exist. You will need to supply full path including filename." } 
            }
        }
        $TmpArr = (Get-Content $FileName | Measure-Object)  
        if ($TmpArr.Count -gt $MaxLines) {
            for ($i = $Keep; $i -ge 1; $i--) {
                $crt = $i
                $prv = $i - 1
                $SrcFile = $FileName + "." + "$prv"
                $DstFile = $FileName + "." + "$crt"
                if ((Test-Path $SrcFile) -and !(get-item "$SrcFile").PSIsContainer) {
                    Move-Item -Force $SrcFile $DstFile 
                }
            }
            $DstFile = $FileName + ".1"
            Move-Item -Force $FileName $DstFile
            New-Item $FileName -type file | out-null
        }
        return @{"ExitCode" = $true; "ExitMsg" = $null } 
    }
    catch {
        return @{"ExitCode" = $false; "ExitMsg" = $error[0].ToString() } 
    }
}
