#
# Start-Stop powershell script
# Note: Automation needs system managed identity with VM Contributor at RG level and Reader at Sub level
# Param for Action: start, stop
# Last updated: 06/02/2023

param (
    [string]$ResourceGroup,
    [string]$VMName,
    [string]$Action
)

# Set manually for testing
# $SubscriptionID = "mysubid"
# $ResourceGroup = "myrg"
# $VMName = "myvm"

if ($ResourceGroup -eq "" -or $VMName -eq "") {
    Write-Output "Required variable uninitialized.";
    exit
}

# Connect using a Managed Service Identity
try
{
    "Logging in to Azure with Managed Service Identity..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

# If you have multiple subscriptions, set the one to use
# Select-AzSubscription -SubscriptionId <SUBSCRIPTIONID>

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect using a Managed Service Identity
try {
        $AzureContext = (Connect-AzAccount -Identity).context
    }
catch{
        Write-Output "There is no system-assigned user identity. Aborting."; 
        exit
    }

Write-Output "Using system-assigned managed identity"

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
Write-Output "Account ID of current context: " $AzureContext.Account.Id

# If you have multiple subscriptions, set the one to use
# Select-AzSubscription -SubscriptionId $SubscriptionID
# Write-Output "Target subscription: $SubscriptionID"
Write-Output "Target resource group: $ResourceGroup"
Write-Output "Target VM: $VMName"

# Get current state of VM
$status = (Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Status -DefaultProfile $AzureContext).Statuses[1].Code
Write-Output "`r`nCurrent status of VM: $status `r`n"

if ($Action -eq "start")
    {
        Write-Output "Starting VM $VMName"
        Start-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -DefaultProfile $AzureContext
    }
elseif ($Action -eq "stop")
    {
        Write-Output "Stoping VM $VMName"
        Stop-AzVM -Name $VMName -ResourceGroupName $ResourceGroup -DefaultProfile $AzureContext -Force
    }
else {
        Write-Output "Nothing else to do. Exciting"
        exit
    }

# Get current state of VM
$status = (Get-AzVM -ResourceGroupName $ResourceGroup -Name $VMName -Status -DefaultProfile $AzureContext).Statuses[1].Code
Write-Output "`r`nCurrent status of VM: $status `r`n"