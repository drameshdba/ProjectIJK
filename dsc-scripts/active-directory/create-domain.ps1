configuration CreatePDC
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

    Import-DscResource -ModuleName xActiveDirectory,xDisk, xNetworking, cDisk, PSDesiredStateConfiguration
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        Script script1
        {
            SetScript =  {
                Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = "[WindowsFeature]DNS"
        }

        Script script2
        {
            SetScript =  {
                Add-DnsServerForwarder -IPAddress 8.8.8.8
                Write-Verbose -Verbose "Add DNS forwarding rule for Internet Access"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature DNS
        {
            Ensure = "Present"
            Name = "DNS"
        }

        WindowsFeature DnsTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
        }

        xDnsServerAddress DnsServerAddress
        {
            Address = '127.0.0.1'
            InterfaceAlias = $InterfaceAlias
            AddressFamily = 'IPv4'
            DependsOn = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk1
        {
             DiskNumber = 1
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }

        cDiskNoRestart ADDataDisk
        {
            DiskNumber = 1
            DriveLetter = "D"
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            DependsOn = "[cDiskNoRestart]ADDataDisk"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomain FirstDS
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "D:\NTDS"
            LogPath = "D:\NTDS"
            SysvolPath = "D:\SYSVOL"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
    }
}
configuration CreateBDC
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [String]$DNSServer,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xActiveDirectory,xDisk, xNetworking, cDisk, PSDesiredStateConfiguration
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        xWaitforDisk Disk1
        {
            DiskNumber = 1
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        cDiskNoRestart ADDataDisk
        {
            DiskNumber = 1
            DriveLetter = "D"
            DependsOn = "[xWaitForDisk]Disk1"
        }

        WindowsFeature ADDSInstall
        {
            Ensure = "Present"
            Name = "AD-Domain-Services"
            DependsOn = "[cDiskNoRestart]ADDataDisk"
        }

        xDnsServerAddress DnsServerAddress
        {
            Address        = $DNSServer
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn="[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainName
            DomainUserCredential= $DomainCreds
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xADDomainController BDC
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "D:\NTDS"
            LogPath = "D:\NTDS"
            SysvolPath = "D:\SYSVOL"
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        Script script1
        {
            SetScript =  {
                $dnsFwdRule = Get-DnsServerForwarder
                if ($dnsFwdRule) { Remove-DnsServerForwarder -IPAddress $dnsFwdRule.IPAddress -Force }
                Write-Verbose -Verbose "Removing DNS forwarding rule"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = "[xADDomainController]BDC"
        }

        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
    }
}