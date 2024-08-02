
# Perforce-Multiserver-Setup

This repository contains scripts to simplify the setup and management of multiple Perforce server instances. These scripts are particularly useful for setting up small teams to use the free tier from Perforce within the bounds of Perforce's terms and conditions.

## Perforce Setup Script

### Description

The `Perforce Setup.ps1` script automates the process of setting up a new Perforce server instance. It allows users to create and configure a Perforce server with a unique server ID and specified port. The script performs several checks, handles existing services, and configures firewall rules.

### Usage

1. **Run the Script**: Execute the script in PowerShell.

   ```powershell
   .\Perforce Setup.ps1
   ```

2. **Enter Inputs**: Provide the necessary inputs when prompted.
   - Unique Server ID (UniqueName)
   - Requested Port (RequestedPort)

3. **Script Execution**:
   - Checks if necessary Perforce executable files exist.
   - Stops and deletes any existing service with the same name.
   - Creates a batch script for setting up the Perforce service.
   - Writes the batch script to a specified location.
   - Adds firewall rules to allow inbound and outbound traffic for the specified port.

# Script Details

\powershell
## Collect user inputs
$UniqueName = Read-Host "Enter the Unique Server ID (UniqueName)"
$RequestedPort = Read-Host "Enter the Port to use (RequestedPort)"
$ServiceName = "Perforce_$UniqueName"

## Paths for Perforce Server executables
$p4dPath = "C:\Program Files\Perforce\Server\p4d.exe"
$p4sPath = "C:\Program Files\Perforce\Server\p4s.exe"
$svcinstPath = "C:\Program Files\Perforce\Server\svcinst.exe"

## Check if necessary files exist before proceeding
if (-Not (Test-Path $p4dPath)) {
    Write-Host "File $p4dPath does not exist. Exiting script."
    exit
}
if (-Not (Test-Path $p4sPath)) {
    Write-Host "File $p4sPath does not exist. Exiting script."
    exit
}
if (-Not (Test-Path $svcinstPath)) {
    Write-Host "File $svcinstPath does not exist. Exiting script."
    exit
}

## Check if service exists
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "Service $ServiceName already exists."
    $confirm = Read-Host "Do you want to stop and delete the existing service? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "Exiting script as service was not allowed to be removed."
        exit
    }
    Stop-Service -Name $ServiceName
    sc.exe delete $ServiceName
    Write-Host "Service $ServiceName stopped and deleted."
}

## Change to the root directory before deleting
Set-Location -Path "E:\"

## Check if directory exists
if (Test-Path $RootDir) {
    Write-Host "Directory $RootDir already exists."
    $confirm = Read-Host "Do you want to delete the existing directory? (Y/N)"
    if ($confirm -ne "Y") {
        Write-Host "Exiting script as directory was not allowed to be removed."
        exit
    }
    Remove-Item -Recurse -Force $RootDir
    Write-Host "Directory $RootDir deleted."
}

## Create batch script content
$batchScriptContent = @"
rem Create the destination directory for the new server.
rem This directory will contain the executable images and the depots.
md E:\P4ROOT_$UniqueName

rem Copy the files to the new directory.
copy "C:\Program Files\Perforce\Server\p4d.exe" E:\P4ROOT_$UniqueName
copy "C:\Program Files\Perforce\Server\p4s.exe" E:\P4ROOT_$UniqueName
copy "C:\Program Files\Perforce\Server\svcinst.exe" E:\P4ROOT_$UniqueName
copy "C:\Program Files\Perforce\Server\license" E:\P4ROOT_$UniqueName
cd /d E:\P4ROOT_$UniqueName

rem Create the service.
svcinst create -n Perforce_$UniqueName -e E:\P4ROOT_$UniqueName\p4s.exe –a

rem Set the service parameters for the new service.
p4 set -S Perforce_$UniqueName P4ROOT=E:\P4ROOT_$UniqueName
p4 set -S Perforce_$UniqueName P4PORT=ssl:$RequestedPort
p4 set -S Perforce_$UniqueName P4LOG=Log_$UniqueName
p4 set -S Perforce_$UniqueName P4JOURNAL=journal_$UniqueName

rem Start the service.
svcinst start -n Perforce_$UniqueName


Note: Add licence file
p4 license

"@

## Write batch script to file
$batchScriptPath = "E:\setup_perforce_$UniqueName.txt"
Set-Content -Path $batchScriptPath -Value $batchScriptContent
Write-Host "Batch script created at $batchScriptPath."

## Add inbound firewall rule
New-NetFirewallRule -DisplayName "Allow Inbound $ServiceName" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $RequestedPort

## Add outbound firewall rule
New-NetFirewallRule -DisplayName "Allow Outbound $ServiceName" -Direction Outbound -Action Allow -Protocol TCP -LocalPort $RequestedPort

Write-Host "Script written, look in 'E:\' to find it. Service added to the firewall."
\```

# Supplementary Script

## Remove Service Script

The `RemoveService.bat` script facilitates the removal of a specified Windows service. It stops the service if it is running and then deletes it.

### Usage

1. **Run the Script**: Execute the batch script.

   \```batch
   .\RemoveService.bat
   \```

2. **Enter Input**: Provide the name of the Windows service to stop and remove when prompted.

### Script Details

\```batch
@echo off
setlocal

rem Prompt the user for the service name
set /p ServiceName=Enter the name of the Windows service to stop and remove: 

rem Check if the service exists
sc query "%ServiceName%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Service "%ServiceName%" does not exist.
    goto :end
)

rem Attempt to stop the service
echo Stopping the service "%ServiceName%"...
sc stop "%ServiceName%"
if %errorlevel% neq 0 (
    echo Service "%ServiceName%" is not running or failed to stop, proceeding to delete.
) else (
    rem Wait for the service to stop
    :waitloop
    timeout /t 1 >nul
    sc query "%ServiceName%" | findstr /i /c:"STOPPED" >nul
    if %errorlevel% neq 0 (
        goto waitloop
    )
    echo Service "%ServiceName%" stopped successfully.
)

rem Remove the service
echo Removing the service "%ServiceName%"...
sc delete "%ServiceName%"
if %errorlevel% neq 0 (
    echo Failed to delete the service "%ServiceName%".
    goto :end
)

echo Service "%ServiceName%" has been successfully removed.

:end
endlocal
pause
\```

## License

This project is licensed under the terms of the GNU GPLv3 license. Please refer to the `LICENSE` file for more information.
