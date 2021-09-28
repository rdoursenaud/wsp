<#
.SYNOPSIS
    A PowerShell script to selectively stop/suspend and start/resume services based on profiles.

.DESCRIPTION
    The WSP.ps1 script switches services profiles and optinnally creates Start Menu
    shortcuts to easily target these profiles.
    The goal is to only run required services for each activity to limit unwanted resources usage
    by mundane services or prevent conflicts.

.PARAMETER Profile
    A profile identifier.
    The special profile 'CS' creates/updates global Start Menu shortcuts to this script for each profile.
    Left empty it prints out the help.

.INPUTS
    None. You cannot pipe objects to WSP.ps1.

.OUTPUTS
    None. WSP.ps1 does not generate output and merely prints services actions.

.EXAMPLE
    PS> .\WSP.ps1 GAME
    Switches to the gaming profile.

.EXAMPLE
    PS> .\WSP.ps1 CS
    Creates global Start Menu shortcuts for each available profile.

.NOTES
    Windows Services Profiles
    Copyright 2021 Raphaël Doursenaud <rdoursenaud@gmail.com>
    License: Microsoft Public License (Ms-PL)
    Uses Get-SpecialFolderPath.ps1 from https://github.com/beatcracker/Powershell-Misc

.LINK
    https://github.com/rdoursenaud/wsp
#>

# RunAsAdministrator was introduced in PowerShell v4.0.
#REQUIRES -Version 4.0
# Since we alter services states and create global Start Menu entries we need administrator privileges.
# #REQUIRES -RunAsAdministrator


###
# Arguments
###

param(
    [string]
    [Parameter(Mandatory = $false)]
    $Profile = ''
)

# Get-SpecialFolderPath may error in strict mode but let’s try it anyway.
# Set-StrictMode -Version 'latest'

# Importing from an absolute path is the best practice
. (Join-Path -Path $PSScriptRoot -ChildPath 'Get-SpecialFolderPath.ps1')


###
# Useful debugging commands
###

# Get-Service | Where-Object { $_.Status -eq "Stopped" } | Format-Table Name | Out-Host -Paging
# Get-Service | Where-Object { $_.Status -eq "Running" } | Format-Table Name | Out-Host -Paging
# Get-Service | Where-Object { $_.Name -like "StartWith*" } | Format-Table Name


###
# Constants
###

# TODO: source from a separate configuration file. One file per profile?

# Resource intensive services.
# We suspend all of them unless they are required by a profile.
$hogs = @(
,'Apple Mobile Device Service'
,'DSAService'
,'DSAUpdateService'
,'Jackett'
,'JetBrainsEtwHost'
,'JTAGServer'
,'LeapService'
,'MullvadVPN'
,'NIHardwareService'
,'NIHostIntegrationAgent'
#,'OVRLibraryService'  # Stopped by OVRService
,'OVRService'
,'NvBroadcast.ContainerLocalSystem'
,'PaceLicenseDServices'
,'Presonus Hardware Access Service'
,'rtpMIDIService'
,'Shibari.Dom.Server'
,'Synergy'
,'TbtHostControllerService'
,'vorpX Service'
,'WD Drive Manager'
)

$ar_required = @(
,'LeapService'
)

$dev_required = @(
,'JetBrainsEtwHost'
,'JTAGServer'
#,'kite'
,'Presonus Hardware Access Service'
)

$game_required = @(
,'Shibari.Dom.Server'
)

$leisure_required = @(
,'Apple Mobile Device Service'
,'Jackett'
,'MullvadVPN'
,'NvBroadcast.ContainerLocalSystem'
,'Presonus Hardware Access Service'  # For HP out
,'Synergy'
,'WD Drive Manager'
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

# 'CS' is currently reserved for creating shortcuts. Don’t use here.
$profiles = @(
,'AR'
,'DEV'
,'GAME'
,'LEISURE'
,'STAN'
,'VR'
,'VRAR'
,'VRGAME'
)

$profiles_required = @{ }

$profiles_required.Add('AR', $ar_required)
$profiles_required.Add('DEV', $dev_required)
$profiles_required.Add('GAME', $game_required)
$profiles_required.Add('LEISURE', $leisure_required)
$profiles_required.Add('STAN', $stan_required)
$profiles_required.Add('VR', $vr_required)
$profiles_required.Add('VRAR', $vrar_required)
$profiles_required.Add('VRGAME', $vrgame_required)

# Sanity checks
$ar_required | Where-Object { $hogs -NotContains $_ }
$dev_required | Where-Object { $hogs -NotContains $_ }
$game_required | Where-Object { $hogs -NotContains $_ }
$leisure_required | Where-Object { $hogs -NotContains $_ }
$stan_required | Where-Object { $hogs -NotContains $_ }
$vr_required | Where-Object { $hogs -NotContains $_ }
$vrar_required | Where-Object { $hogs -NotContains $_ }
$vrgame_required | Where-Object { $hogs -NotContains $_ }
$profiles_required.Keys | Where-Object { $profiles -NotContains $_ }


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
        If (Get-Service $Service | Where-Object { $_.Status -eq "Running" -or $_.Status -eq "Paused" })
        {

            Write-Host "- $Service"

            try
            {
                Stop-Service $Service -ErrorAction Stop
            }
            catch
            {
                Write-Host "Service $Service cannot be stopped. Trying to suspend it."

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

        If (Get-Service $Service | Where-Object { $_.Status -eq "Stopped" })
        {
            Start-Service $Service
        }
        elseif (Get-Service $Service | Where-Object { $_.Status -eq "Paused" })
        {
            Resume-Service $Service
        }

    }
}


####
# Main
####

If ($Profile -eq 'CS')
{
    # FIXME: Remove old shortcuts safely?

    # Create shortcuts
    $CSIDL_COMMON_STARTMENU = Get-SpecialFolderPath -Name CSIDL_COMMON_STARTMENU
    $script = $script:MyInvocation.MyCommand.Path
    $WshShell = New-Object -ComObject WScript.Shell
    $powershell = (Get-Process -Id $pid).Path
    foreach ($Profile in $profiles)
    {
        $lnkPath = "$CSIDL_COMMON_STARTMENU\WSP-$Profile.lnk"
        $lnk = $WshShell.CreateShortcut($lnkPath)
        $lnk.TargetPath = "$powershell"
        $lnk.Arguments = "$script $Profile"
        $lnk.Save()

        # Hackery to force starting with elevated privileges
        $bytes = [System.IO.File]::ReadAllBytes($lnkPath)
        $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
        [System.IO.File]::WriteAllBytes($lnkPath, $bytes)
    }
}
ElseIf ($profiles.Contains($Profile))
{
    $required = $profiles_required[$Profile]
    $stop = $hogs | Where-Object { $required -NotContains $_ }
    Stop-Services($stop)
    Start-Services($required)
}
ElseIf ($Profile -eq '')
{
    Get-Help $PSCommandPath -full
}
Else
{
    Write-Error "Unknown profile: $Profile"
}
