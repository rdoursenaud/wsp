# Windows Services Profiles
#
# Copyright 2021 Raphael Doursenaud <rdoursenaud@gmail.com>
#
# Selectively suspend and resume services based on profiles/modes
#

###
# Arguments
###

param(
    [Parameter(Mandatory = $true)] $Mode = ""
)


Set-StrictMode -Version 'latest'
#Requires -RunAsAdministrator

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
$ar_required | Where {$hogs -NotContains $_}
$dev_required | Where {$hogs -NotContains $_}
$game_required | Where {$hogs -NotContains $_}
$leisure_required | Where {$hogs -NotContains $_}
$stan_required | Where {$hogs -NotContains $_}
$vr_required | Where {$hogs -NotContains $_}
$vrar_required | Where {$hogs -NotContains $_}
$vrgame_required | Where {$hogs -NotContains $_}
$modes_required.Keys | Where {$modes -NotContains $_}

###
# Functions
###

function Help
{
    Write-Host "Usage: wsp.ps -Mode [ModeName]}"
    Write-Host ""
    Write-Host "Available modes: $modes"
}

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

If ($Mode -eq "")
{
    Help
}
ElseIf ($modes.Contains($Mode))
{
    Write-Host "WIP"
    $required = $modes_required[$Mode]
    $stop =  $hogs | Where {$required -NotContains $_}
    Stop-Services($stop)
    Start-Services($required)
}
Else
{
    Write-Error "Unknown mode: $Mode"
    Help
}