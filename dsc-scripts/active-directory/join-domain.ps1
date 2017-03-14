configuration Main
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xComputerManagement,xActiveDirectory
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    if ($DomainName)
    {
        $RebootVirtualMachine = $true
    }

    Node localhost
    {
        WindowsFeature ADPS
        {
            Name = "RSAT-AD-PowerShell"
            Ensure = "Present"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
	        DependsOn = "[WindowsFeature]ADPS"
        }

        xComputer DomainJoin
        {
            Name = $env:COMPUTERNAME
            DomainName = $DomainName
            Credential = $DomainCreds
	        DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }
    }
}