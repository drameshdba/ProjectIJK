Configuration CreateFileShareWitness
{

    Param
    (

        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory)]
        [String]$SharePath,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xComputerManagement,xSmbShare,cDisk,xDisk,xActiveDirectory
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)

    if ($DomainName)
    {
        $RebootVirtualMachine = $true
    }

    Node localhost
    {
        xWaitforDisk Disk1
        {
                DiskNumber = 1
                RetryIntervalSec =$RetryIntervalSec
                RetryCount = $RetryCount
        }

        cDiskNoRestart DataDisk
        {
            DiskNumber = 1
            DriveLetter = "D"
        }

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

        File FSWFolder
        {
            DestinationPath = "D:\$($SharePath.ToUpperInvariant())"
            Type = "Directory"
            Ensure = "Present"
            DependsOn = "[xComputer]DomainJoin"
        }

        xSmbShare FSWShare
        {
            Name = $SharePath.ToUpperInvariant()
            Path = "D:\$($SharePath.ToUpperInvariant())"
            FullAccess = "BUILTIN\Administrators"
            Ensure = "Present"
            DependsOn = "[File]FSWFolder"
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

    }

}