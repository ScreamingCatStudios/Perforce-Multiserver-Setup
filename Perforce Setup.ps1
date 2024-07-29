# Collect user inputs
$UniqueName = Read-Host "Enter the Unique Server ID (UniqueName)"
$RequestedPort = Read-Host "Enter the Port to use (RequestedPort)"
$ServiceName = "Perforce_$UniqueName"

# Paths for Perforce Server executables
$p4dPath = "C:\Program Files\Perforce\Server\p4d.exe"
$p4sPath = "C:\Program Files\Perforce\Server\p4s.exe"
$svcinstPath = "C:\Program Files\Perforce\Server\svcinst.exe"

# Check if necessary files exist before proceeding
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

# Check if service exists
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

# Change to the root directory before deleting
Set-Location -Path "E:\"

# Check if directory exists
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

# Create batch script content
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

# Write batch script to file
$batchScriptPath = "E:\setup_perforce_$UniqueName.txt"
Set-Content -Path $batchScriptPath -Value $batchScriptContent
Write-Host "Batch script created at $batchScriptPath."

# Add inbound firewall rule
New-NetFirewallRule -DisplayName "Allow Inbound $ServiceName" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $RequestedPort

# Add outbound firewall rule
New-NetFirewallRule -DisplayName "Allow Outbound $ServiceName" -Direction Outbound -Action Allow -Protocol TCP -LocalPort $RequestedPort

Write-Host "Script written, look in 'E:\' to find it. Service added to the firewall."