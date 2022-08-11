Write-Host ""
Write-Host "A) Collect new Baseline?"
Write-Host "B) Begin monitoring files with saved Baseline?"

$response = Read-Host -Prompt "Please enter 'A' or 'B'"

# Take file path, calculate it, and then return hash
Function Calculate-File-Hash ($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline(){
    $BaselineExists = Test-Path -Path .\baseline.txt
    if ($BaselineExists){
        # Clear baseline.txt file
        Remove-Item -Path .\baseline.txt
    }
}

Function Monitor-Baseline(){
    if (Test-Path -Path .\baseline.txt){
    # Declare dictionary
    $fileHashDict = @{}

    # Load file hash from baseline.txt and store in a dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    
    foreach ($f in $filePathsAndHashes){
       $fileHashDict.add($f.Split("|")[0], $f.Split("|")[1])
    }

    # Begin continuously monitoring files with saved Baseline
    while ($true){
        Start-Sleep -Seconds 1
    
    # Monitors every folder in the baseline
    foreach($i in $FolderArray){
        $files = Get-ChildItem -Path .\$i

        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName

            # A new file has been created 
            if ($fileHashDict[$hash.Path] -eq $null) {
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }

            # A file has been changed
            else{
                if($fileHashDict[$hash.Path] -eq $hash.Hash){
                    # File has not changed. No need to notify.
                }
                else{
                # File has been modified
                Write-Host "$($hash.Path) has changed!" -ForegroundColor Yellow
                }
            }
        }
    }

        # Checks if a baseline file has been deleted
        foreach ($key in $fileHashDict.Keys){
                Start-Sleep -Seconds 1
                $baselineStillExists = Test-Path -Path $key
                if (-Not $baselineStillExists){
                 # A baseline file has been deleted, notify logs.
                Write-Host "$($key) has been deleted!" -ForegroundColor Red
                }
            }
        }
    }
    # Error-handling. A baseline needs to be created before monitored.
    else{
        Write-Host "A baseline does not exist. Please create one." -ForegroundColor Blue
    }
}

if($response -eq "A".ToUpper()){
    # Clears all the text in baseline.txt
    Erase-Baseline

    # Array of what folders are being used for baseline.txt
    $FolderArray = @()

    # Calculate Hash from target files and store in baseline.txt
    
    # Collect all files in target folder
    while ($true){
    $baselineFolder = Read-Host -Prompt "Which folder would you like to set a baseline for? To end the prompt, do not input any text and press enter"
    if ($baselineFolder -eq ""){
        break
    }
    else{
    $FolderArray += $baselineFolder
    $files = Get-ChildItem -Path .\$baselineFolder

    # Calculate the hash of each file and write to baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
        }
     }
    }

    # Monitor the newly created baseline
    Read-Host "$FolderArray"
    $MonitorQuestion = Read-Host -Prompt "Would you like to monitor the new baseline? If so, type YES"
    if ($MonitorQuestion.ToUpper() -eq "YES"){
        Monitor-Baseline
    }
}

# Skips setting up baseline and automatically monitors
elseif ($response -eq "B".ToUpper()){
    Monitor-Baseline
}
