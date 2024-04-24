Clear-Host

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$exePath = "C:\Program Files\Sublime Text\sublime_text.exe"
$sublPath = "C:\Program Files\Sublime Text\subl.exe"

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Test-Path $exePath)) {
    Write-Host "Sublime Text executable not found at $exePath. Please ensure Sublime Text is installed under its default location.`n" -BackgroundColor Red
    pause
    exit
}

# Check if the script is running with administrative privileges, if no, ask for elevation.
if (-Not (Test-Admin))  {
    if ($elevated) {
        #
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    exit
    }
    exit
}

try {
    $versionOutput = & $sublPath --version
    $buildNumber = $versionOutput -replace '.*Build (\d+).*', '$1'
} catch {
    Write-Host "Failed to retrieve Sublime Text version. Aborting.`n" -BackgroundColor Red
    pause
    exit
}

Write-Host "Detected Sublime Text build: [$buildNumber]`n"

$sublimeProcesses = Get-Process -Name sublime_text -ErrorAction SilentlyContinue
if ($sublimeProcesses) {
    Write-Host "Sublime Text is currently running. Closing all instances..`n"
    $sublimeProcesses | Stop-Process -Force
    Write-Host "All instances of Sublime Text have been closed.`n"
}


if ($buildNumber -eq 4169) {
    Write-Host "Patching Sublime Text..`n"
    try {
        $byteArray = [System.IO.File]::ReadAllBytes($exePath)
        $byteString = $byteArray.ForEach('ToString', 'X2') -join ' '
        $searchString = '80 78 05 00 0F 94 C1'
        $replacementString = 'C6 40 05 01 48 85 C9'
        $byteString = $byteString -replace $searchString, $replacementString
        [byte[]] $newByteArray = $byteString -split ' ' | ForEach-Object { [byte]("0x$_") }
        [System.IO.File]::WriteAllBytes($exePath, $newByteArray)
        Write-Host "Sublime Text has been patched successfully`n" -BackgroundColor Green
        pause
        exit
    } catch {
        Write-Host "Failed to patch Sublime Text. Aborting.`n" -BackgroundColor Red
        pause
        exit
    }
} else {
    Write-Host "Unsupported Sublime Text version [$buildNumber]. Aborting the script.`n" -BackgroundColor Red
    pause
    exit
}
