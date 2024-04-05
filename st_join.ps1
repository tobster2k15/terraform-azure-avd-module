param(
	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $ClientId,
	
	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $SubscriptionId,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $ResourceGroupName,

	[Parameter(Mandatory = $false)]
	[ValidateNotNullOrEmpty()]
	[string]$StorageAccountName,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $SamAccountName,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $DomainAccountType,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $OUName,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $EncryptionType,

    [Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $IdentityServiceProvider,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $StorageAccountFqdn
	
)

$ErrorActionPreference = "Stop"

# Imortiere Logger und setze Variable für $Path
If ($PSScriptRoot)
{
    $Path = $PSScriptRoot
	. (Join-Path $Path "Logger.ps1")
}
else 
{
    $Path = $MyInvocation.MyCommand.Path
	. (Join-Path $Path "Logger.ps1")
}

# Importiere Module für die Ausfuehrung
try 
{
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Install-Module -Name PowershellGet -MinimumVersion 2.2.4.1 -Force
    Install-Module -Name Az.Accounts -Force
    Install-Module -Name Az.Storage -Force
    Install-Module -Name Az.Network -Force
    Install-Module -Name Az.Resources -Force

    Write-Log("Loaded module")
}
catch 
{
    $exception = $_
    Write-Log("Error loading Module",$true,$exception)
}

# Importiere  AzFilesHybrid module wenn der ServiceProvider ADDS ist
if ($IdentityServiceProvider -eq 'ADDS') 
{
	Write-Log "Installing AzFilesHybrid module"
    
    try
    {
        $AzFilesZipLocation = Get-ChildItem -Path $Path -Filter "AzFilesHybrid*.zip"
        Expand-Archive $AzFilesZipLocation.FullName -DestinationPath $Path -Force
        Set-Location $Path
        $AzFilesHybridPath = (Join-Path $Path "CopyToPSPath.ps1")
        & $AzFilesHybridPath
    }
    catch {
        $exception = $_
        Write-Log("Error installing AzFilesHybrid module",$true,$exception)
    }
	
    # Lade AD Modul
    try 
    {
	Import-Module -Name AzFilesHybrid -Force
	$ADModule = Get-Module -Name ActiveDirectory
        if (-not $ADModule) {
            Request-OSFeature -WindowsClientCapability "Rsat.ActiveDirectory.DS-LDS.Tools" -WindowsServerFeature "RSAT-AD-PowerShell"
            Import-Module -Name activedirectory -Force -Verbose
        }
    }
    catch {
        $exception = $_
        Write-Log("Error imorting AD-Module",$true,$exception)
    }

    # Prüfe ob der StorageAccountName bereits Domain joined ist
    try
    {
        $IsStorageAccountDomainJoined = Get-ADObject -Filter 'ObjectClass -eq "Computer"' | Where-Object { $_.Name -eq $StorageAccountName }

        # Wenn ja beende Script
        if ($IsStorageAccountDomainJoined) 
        {
            Write-Log "Storage account $StorageAccountName is already domain joined."
            exit
        }
        # Wenn nicht mache den Domain Join
        else 
        {
            Write-Log "Connecting to managed identity account"
            Connect-AzAccount -Identity -AccountId $ClientId 

            Write-Log "Setting Azure subscription to $SubscriptionId"
            Select-AzSubscription -SubscriptionId $SubscriptionId

            if ($IdentityServiceProvider -eq 'ADDS') 
            {
                Write-Log "Domain joining storage account $StorageAccountName in Resource group ResourceGroupName"
                if ( $CustomOuPath -eq 'true') {
                    #Join-AzStorageAccountForAuth -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -DomainAccountType 'ComputerAccount' -OrganizationalUnitDistinguishedName $OUName -OverwriteExistingADObject
                    Join-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -OrganizationalUnitDistinguishedName $OUName -DomainAccountType $DomainAccountType -EncryptionType $EncryptionType -OverwriteExistingADObject #-SamAccountName $SamAccountName
                    Write-Log -Message "Successfully domain joined the storage account $StorageAccountName to custom OU path $OUName"
                }
                else 
                {
                    #Join-AzStorageAccountForAuth -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -DomainAccountType 'ComputerAccount' -OrganizationalUnitName $OUName -OverwriteExistingADObject
                    Join-AzStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -OrganizationalUnitName $OUName -DomainAccountType $DomainAccountType -EncryptionType $EncryptionType -OverwriteExistingADObject #-SamAccountName $SamAccountName
                    Write-Log -Message "Successfully domain joined the storage account $StorageAccountName to default OU path $OUName"
                }
            }

            $connectTestResult = Test-NetConnection -ComputerName $StorageAccountFqdn -Port 445
            Write-Log "$connectTestResult"
        }
    }
    catch 
    {
        $exception = $_
        Write-Log("Error checking or joining storage to domain",$true,$exception)
    }
    
}

