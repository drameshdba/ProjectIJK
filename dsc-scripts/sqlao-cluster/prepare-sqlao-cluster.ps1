configuration PrepareAlwaysOnSqlServer
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SQLServicecreds,

        [Parameter(Mandatory)]
        [String]$SqlAlwaysOnEndpointName,

        [UInt32]$DatabaseEnginePort,

        [Parameter(Mandatory)]
        [UInt32]$NumberOfDisks,

        [Parameter(Mandatory)]
        [String]$WorkloadType,

        [String]$DomainNetbiosName=(Get-NetBIOSName -DomainName $DomainName),

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    )

    Import-DscResource -ModuleName xComputerManagement,cDisk,xActiveDirectory,xDisk,xSql,xSQLServer,xSQLps,xNetworking
    [System.Management.Automation.PSCredential]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($Admincreds.UserName)", $Admincreds.Password)
    [System.Management.Automation.PSCredential]$DomainFQDNCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    [System.Management.Automation.PSCredential]$SQLCreds = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($SQLServicecreds.UserName)", $SQLServicecreds.Password)

    $RebootVirtualMachine = $false

    if ($DomainName)
    {
        $RebootVirtualMachine = $true
    }
       
    Node localhost
    {        
        WindowsFeature FC
        {
            Name = "Failover-Clustering"
            Ensure = "Present"
        }

        WindowsFeature FailoverClusterTools
        {
            Ensure = "Present"
            Name = "RSAT-Clustering-Mgmt"
            DependsOn = "[WindowsFeature]FC"
        }

        WindowsFeature FCPS
        {
            Name = "RSAT-Clustering-PowerShell"
            Ensure = "Present"
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

        xFirewall DatabaseEngineFirewallRule
        {
            Name                  = 'SQL-Server-Database-Engine-TCP-In'
            DisplayName           = 'SQL Server Database Engine (TCP-In)'
            Group                 = 'SQL Server'
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Domain', 'Private')
            Direction             = 'Inbound'
            LocalPort             = $DatabaseEnginePort -as [String]
            Protocol              = 'TCP'
            Description           = 'Inbound rule for SQL Server to allow TCP traffic for the Database Engine.'
        }

        xFirewall DatabaseMirroringFirewallRule
        {
            Name                  = 'SQL-Server-Database-Mirroring-TCP-In'
            DisplayName           = 'SQL Server Database Mirroring (TCP-In)'
            Group                 = 'SQL Server'
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Domain', 'Private')
            Direction             = 'Inbound'
            LocalPort             = '5022'
            Protocol              = 'TCP'
            Description           = 'Inbound rule for SQL Server to allow TCP traffic for the Database Mirroring.'
        }

        xFirewall ListenerFirewallRule
        {
            Name                  = 'SQL-Server-Availability-Group-Listener-TCP-In'
            DisplayName           = 'SQL Server Availability Group Listener (TCP-In)'
            Group                 = 'SQL Server'
            Ensure                = 'Present'
            Enabled               = 'True'
            Profile               = ('Domain', 'Private')
            Direction             = 'Inbound'
            LocalPort             = '59999'
            Protocol              = 'TCP'
            Description           = 'Inbound rule for SQL Server to allow TCP traffic for the Availability Group listener.'
        }

        xSqlLogin AddDomainAdminAccountToSysadminServerRole
        {
            Name = $DomainCreds.UserName
            LoginType = "WindowsUser"
            ServerRoles = "sysadmin"
            Enabled = $true
            Credential = $Admincreds
        }

        xADUser CreateSqlServerServiceAccount
        {
            DomainAdministratorCredential = $DomainCreds
            DomainName = $DomainName
            UserName = $SQLServicecreds.UserName
            Password = $SQLServicecreds
            Ensure = "Present"
            DependsOn = "[xSqlLogin]AddDomainAdminAccountToSysadminServerRole"
        }

        xSqlLogin AddSqlServerServiceAccountToSysadminServerRole
        {
            Name = $SQLCreds.UserName
            LoginType = "WindowsUser"
            ServerRoles = "sysadmin"
            Enabled = $true
            Credential = $Admincreds
            DependsOn = "[xADUser]CreateSqlServerServiceAccount"
        }

        xSqlTsqlEndpoint AddSqlServerEndpoint
        {
            InstanceName = "MSSQLSERVER"
            PortNumber = $DatabaseEnginePort
            SqlAdministratorCredential = $Admincreds
            DependsOn = "[xSqlLogin]AddSqlServerServiceAccountToSysadminServerRole"
        }

        xSQLServerStorageSettings AddSQLServerStorageSettings
        {
            InstanceName = "MSSQLSERVER"
            OptimizationType = $WorkloadType
            DependsOn = "[xSqlTsqlEndpoint]AddSqlServerEndpoint"
        }

        xSqlServer ConfigureSqlServerWithAlwaysOn
        {
            InstanceName = $env:COMPUTERNAME
            SqlAdministratorCredential = $Admincreds
            ServiceCredential = $SQLCreds
            MaxDegreeOfParallelism = 1
            FilePath = "F:\DATA"
            LogPath = "F:\LOG"
            DomainAdministratorCredential = $DomainFQDNCreds
            EnableTcpIp = $true
            DependsOn = "[xSqlLogin]AddSqlServerServiceAccountToSysadminServerRole"
        }

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

    }
}
function Get-NetBIOSName
{
    [OutputType([string])]
    param(
        [string]$DomainName
    )

    if ($DomainName.Contains('.')) {
        $length=$DomainName.IndexOf('.')
        if ( $length -ge 16) {
            $length=15
        }
        return $DomainName.Substring(0,$length)
    }
    else {
        if ($DomainName.Length -gt 15) {
            return $DomainName.Substring(0,15)
        }
        else {
            return $DomainName
        }
    }
}
