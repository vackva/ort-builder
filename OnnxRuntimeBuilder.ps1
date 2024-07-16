Add-Type -AssemblyName System.Windows.Forms # Required for file dialog

# Global configuration file path
$configFilePath = "pythonpath.txt"

# Custom function to display the menu (replace with your actual menu display logic if needed)
function Show-Menu {
    param (
        [string]$Title
    )
    Clear-Host
    Write-Host "====== $Title ======"
    # Write-Host "1: Build ONNX Runtime version 1.14.1 MinSizeRelease"
    Write-Host "2: Build ONNX Runtime version 1.14.1 Debug"
    # Write-Host "3: Build ONNX Runtime version 1.16.2 MinSizeRelease"
    Write-Host "4: Build ONNX Runtime version 1.16.2 Debug"
    Write-Host "===================="
}

# Check if the path points to python.exe and the file exists
function IsValidPythonPath($path) {
    return ($path -like "*python.exe") -and (Test-Path $path)
}

# Get the Python path, either from a config file or user input
function GetCustomPythonPath($minVersion = 308, $maxVersion = 311) {
    if (Test-Path $configFilePath) {
        $path = Get-Content $configFilePath
        if (IsValidPythonPath $path) {
            Write-Host "Found Python path in pythonpath.txt"
            return $path
        }
    }

    # add dots to python version
    $minVersionStr = $minVersion -replace '(\d{1})(\d{2})', '$1.$2'
    $maxVersionStr = $maxVersion -replace '(\d{1})(\d{2})', '$1.$2'
    $dialogue = "Select Python $minVersionStr-$maxVersionStr executable"

    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "Python Executable|python.exe"
    $fileDialog.Title = $dialogue
    Write-Host $dialogue

    do {
        $result = $fileDialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $path = $fileDialog.FileName
        } else {
            Write-Host "No file selected, please try again."
        }
    } while (-not (IsValidPythonPath $path))

    Set-Content -Path $configFilePath -Value $path
    return $path
}

function ExtractTarball($tarGzPath, $destinationDir) {
    # Create the destination directory if it doesn't exist
    if (-not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir
    }

    # Extract tar.gz
    # x = extract, z = gzip & file is .tar.gz or .tgz, v = verbose, f = next arg is filename
    tar -xzf $tarGzPath -C $destinationDir

    # Optionally, remove the compressed file
    # Remove-Item $tarGzPath
}

function ValidatePythonVersion($pythonPath, $minVersion = 308, $maxVersion = 311)
{
    # Validate the installed Python version

    $pythonVersionOutput = & $pythonPath --version 2>&1
    $pythonVersionMatch = [regex]::Match($pythonVersionOutput, 'Python (\d+)\.(\d+)')

    if ($pythonVersionMatch.Success) {
        $majorVersion = [int]$pythonVersionMatch.Groups[1].Value
        $minorVersion = [int]$pythonVersionMatch.Groups[2].Value
        $pythonVersion = $majorVersion * 100 + $minorVersion

        # Compare using integer comparison
        if ($pythonVersion -lt $minVersion -or $pythonVersion -gt $maxVersion) {
            $minVersionStr = $minVersion -replace '(\d{1})(\d{2})', '$1.$2'
            $maxVersionStr = $maxVersion -replace '(\d{1})(\d{2})', '$1.$2'
            Write-Host "Python version is not in the required range ($maxVersionStr-$minVersionStr). Found version: $pythonVersion"
            return $false
        }
        else
        {       
            Write-Host "Python version is in the required range $minVersion - $maxVersion. Found version: $pythonVersion"
            return $true
        }
    } else {
        throw "Unable to determine Python version. Output: $pythonVersionOutput"
    }
}

try {
    # Get user selection
    Show-Menu -Title 'Select ONNX Runtime version to build, max python version is determined by the ONNX Runtime version'
    $selection = Read-Host "Please select the version to build, using 2 or 4"

    # Determine the version to build based on selection
    # ONNX Runtime 1.14.1 requires Python 3.7-3.10
    # ONNX Runtime 1.16.2 requires Python 3.8-3.11
    # minSizeRelease requires .ort model using ort-builder, this is not included yet
    switch ($selection) {
        # "1" { 
        #     $onnxruntimeVersion = "1.14.1" 
        #     $minReqVersion = 307
        #     $maxReqVersion = 310
        #     $buildType = "MinSizeRelease"}
        "2" {
            $onnxruntimeVersion = "1.14.1" 
            $minReqVersion = 307
            $maxReqVersion = 310
            $buildType = "Debug"}
        # "3" {
        #     $onnxruntimeVersion = "1.16.2" 
        #     $minReqVersion = 308
        #     $maxReqVersion = 311
        #     $buildType = "MinSizeRelease"}
        "4" {
            $onnxruntimeVersion = "1.16.2" 
            $minReqVersion = 308
            $maxReqVersion = 311
            $buildType = "Debug"}
        default { Write-Host "Invalid selection"; exit }
    }
    Write-Host "Selected ONNX Runtime version: $onnxruntimeVersion, build type: $buildType"

    # Set the ONNX Runtime folder name
    $onnx_rt_folder = "onnxruntime-$onnxruntimeVersion"


    # --- Get & validate Python path + version, either from config file or user input ---
    Write-Host "`nGetting System Python"
    $pythonPath = (Get-Command python).Source

    while (-not (ValidatePythonVersion $pythonPath $minReqVersion $maxReqVersion)) {
        $pythonPath = GetCustomPythonPath $minReqVersion $maxReqVersion
    }

    
    # --- Download ONNX Runtime tarball, if doesnt exist ---
    Write-Host "`nDownloading and Extracting $onnx_rt_folder.tar.gz"
    $downloadPath = "$onnx_rt_folder.tar.gz"
    if (-not (Test-Path $downloadPath)) {
        Write-Host "Downloading $onnxruntimeVersion"
        Invoke-WebRequest -Uri "https://github.com/microsoft/onnxruntime/archive/refs/tags/v$onnxruntimeVersion.tar.gz" -OutFile $downloadPath
    } else {
        Write-Host "$downloadPath is already downloaded."
    }


    # --- Extract ONNX Runtime, if hasn't been extracted ---
    $extractPath = "$onnx_rt_folder\"
    if (-not (Test-Path $extractPath)) {
        Write-Host "`nExtracting onnxruntime"
        # Replace ExtractTarball with the correct command or function to extract the tarball
        ExtractTarball -tarGzPath $downloadPath -destinationDir $extractPath
        Write-Host "`nFinished Extracting onnxruntime."

        # move contents of onnxruntime-1.16.2 to onnxruntime
        Write-Host "Moving contents of $onnx_rt_folder to onnxruntime"
        Move-Item -Path "$extractPath\$onnx_rt_folder\*" -Destination "$extractPath\"
        # remove now empty folder
        Write-Host "Removing $onnx_rt_folder"
        Remove-Item -Path "$extractPath\$onnx_rt_folder\"
    } else {
        Write-Host "$onnx_rt_folder is already extracted."
    }

    Write-Host "Navigating to \$onnx_rt_folder\ `n"
    Push-Location ".\$onnx_rt_folder\"


    # --- Create virtual environment if it doesn't exist ---
    if (Test-Path .\venv) {
        Write-Host "Virtual environment exists."
        . .\venv\Scripts\Activate.ps1
    } else {
        Write-Host "Creating new venv using Python $pythonPath"
        & $pythonPath -m venv venv
    }
    Write-Host "Activating venv"
    . .\venv\Scripts\Activate.ps1

    Write-Host "Initializing ONNXRuntime Submodules"
    git submodule init
    Write-Host "Updating ONNXRuntime Submodules"
    git submodule update

    Write-Host "Setup Complete.`n"


    # --- Call build script, passing the ONNX Runtime folder name (e.g. onnxruntime-1.16.2) ---
    Read-Host -Prompt "Press Enter to start Build"
    Pop-Location # Go back to base directory

    if ($buildType -eq "MinSizeRelease") {
        cmd /c ".\build-win_minSizeRelease.bat $onnx_rt_folder"
    }
    elseif ($buildType -eq "Debug") {
        cmd /c ".\build-win_debug.bat $onnx_rt_folder"
    }
    else {
        Write-Host "Invalid build type"
    }
}

catch {
    Write-Host "An error occurred: $_"
}

# Keep the PowerShell window open
Read-Host -Prompt "Press Enter to exit"