<#
Windows Services Profiles
Copyright 2021 Raphael Doursenaud <rdoursenaud@gmail.com>

.Synopsis
    Selectively suspend and resume services based on profiles/modes

.Parameter Mode
    A mode identifier
 #>

###
# Arguments
###

param(
    [Parameter(Mandatory = $true)] $Mode = ""
)

#
#Set-StrictMode -Version 'latest'  # Get-SpecialFolderPath errors in strict mode
#Requires -RunAsAdministrator

$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path
. (Join-Path -Path $ScriptDir -ChildPath 'Get-SpecialFolderPath.ps1')


###
# Useful debugging commands
###

#Get-Service | Where { $_.Status -eq "Stopped" } | Format-Table Name | Out-Host -Paging
#Get-Service | Where { $_.Status -eq "Running" } | Format-Table Name | Out-Host -Paging
#Get-Service | Where { $_.Name -like "StartWith*" } | Format-Table Name

###
# Constants
###

# Resource intensive services
$hogs = @(
,'Apple Mobile Device Service'
,'DSAService'
,'DSAUpdateService'
,'Intel(R) PROSet Monitoring Service'
,'Jackett'
,'JTAGServer'
,'LeapService'
,'MullvadVPN'
,'NIHardwareService'
,'NIHostIntegrationAgent'
#,'OVRLibraryService'  # Stopped by OVRService
,'OVRService'
,'PaceLicenseDServices'
,'Presonus Hardware Access Service'
,'rtpMIDIService'
,'Shibari.Dom.Server'
,'Synergy'
,'TbtHostControllerService'
,'vorpX Service'
)

$ar_required = @(
,'LeapService'
)

$dev_required = @(
,'JTAGServer'
#,'kite'
)

$game_required = @(
,'Shibari.Dom.Server'
)

$leisure_required = @(
,'Apple Mobile Device Service'
,'Jackett'
,'MullvadVPN'
,'Synergy'
)

$stan_required = @(
,'Apple Mobile Device Service'
,'NIHardwareService'
,'NIHostIntegrationAgent'
,'PaceLicenseDServices'
,'Presonus Hardware Access Service'
,'rtpMIDIService'
,'TbtHostControllerService'
)

$vr_required = @(
#,'OVRLibraryService'  # Started by OVRService
,'OVRService'
)

$vrar_required = $vr_required + $ar_required

$vrgame_required = $vr_required + @(
,'vorpX Service'
)

$modes = @(
,'AR'
,'DEV'
,'GAME'
,'LEISURE'
,'STAN'
,'VR'
,'VRAR'
,'VRGAME'
)

$modes_required = @{ }

$modes_required.Add('AR', $ar_required)
$modes_required.Add('DEV', $dev_required)
$modes_required.Add('GAME', $game_required)
$modes_required.Add('LEISURE', $leisure_required)
$modes_required.Add('STAN', $stan_required)
$modes_required.Add('VR', $vr_required)
$modes_required.Add('VRAR', $vrar_required)
$modes_required.Add('VRGAME', $vrgame_required)

# Sanity checks
$ar_required | Where { $hogs -NotContains $_ }
$dev_required | Where { $hogs -NotContains $_ }
$game_required | Where { $hogs -NotContains $_ }
$leisure_required | Where { $hogs -NotContains $_ }
$stan_required | Where { $hogs -NotContains $_ }
$vr_required | Where { $hogs -NotContains $_ }
$vrar_required | Where { $hogs -NotContains $_ }
$vrgame_required | Where { $hogs -NotContains $_ }
$modes_required.Keys | Where { $modes -NotContains $_ }

###
# Functions
###
function Stop-Services
{
    param (
        $ServicesList
    )

    Write-Host "Stopping:"

    foreach ($Service in $ServicesList)
    {
        If (Get-Service $Service | Where { $_.Status -eq "Running" -or $_.Status -eq "Paused" })
        {

            Write-Host "- $Service"

            try
            {
                Stop-Service $Service -ErrorAction Stop
            }
            catch
            {
                Write-Host "`tService $Service cannont be stopped. Trying to suspend it."

                Suspend-Service $Service
            }
        }
    }
}

function Start-Services
{
    param (
        $ServicesList
    )

    Write-Host "Starting:"

    foreach ($Service in $ServicesList)
    {
        Write-Host "- $Service"

        If (Get-Service $Service | Where { $_.Status -eq "Stopped" })
        {
            Start-Service $Service
        }
        elseif (Get-Service $Service | Where { $_.Status -eq "Paused" })
        {
            Resume-Service $Service
        }

    }
}

####
# Main
####

If ($Mode -eq "CS")
{
    # Create shortcuts
    $CSIDL_COMMON_STARTMENU = Get-SpecialFolderPath -Name CSIDL_COMMON_STARTMENU
    $script = $script:MyInvocation.MyCommand.Path
    $WshShell = New-Object -ComObject WScript.Shell
    foreach ($mode in $modes)
    {
        $lnkPath = "$CSIDL_COMMON_STARTMENU\WSP-$mode.lnk"
        $lnk = $WshShell.CreateShortcut($lnkPath)
        $lnk.TargetPath = "$PSHome\pwsh.exe"
        $lnk.Arguments = "$script $mode"
        $lnk.Save()

        # Hackery to force tarting with elevated privileges
        $bytes = [System.IO.File]::ReadAllBytes($lnkPath)
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes($lnkPath, $bytes)
    }
}
ElseIf ($modes.Contains($Mode))
{
    $required = $modes_required[$Mode]
    $stop = $hogs | Where { $required -NotContains $_ }
    Stop-Services($stop)
    Start-Services($required)
}
Else
{
    Write-Error "Unknown mode: $Mode"
}