# Configure Windows 10 for automation using Ansible

# Enable WinRM (Win 7 case):
# To enable WinRM on Windows 7, run the following command in PowerShell (as Administrator): powershell
winrm quickconfig -Force  # Will need to disable HTTP later after configuring HTTPS

# Enable PowerShell remoting (Win 7 case)
# Enable-PSRemoting -Force # May not be required if using HTTPS

# Set WinRM service startup type to automatic
Set-Service WinRM -StartupType 'Automatic'

# Configure WinRM Service
# But first set the interfaces from public to private if necessary
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
Set-NetConnectionProfile -InterfaceAlias "Ethernet 2" -NetworkCategory Private
Set-Item -Path WSMan:\localhost\Service\Auth\Certificate -Value $true
Set-Item -Path 'WSMan:\localhost\Service\AllowUnencrypted' -Value $false
Set-Item -Path 'WSMan:\localhost\Service\Auth\Basic' -Value $true
Set-Item -Path 'WSMan:\localhost\Service\Auth\CredSSP' -Value $true

Create a self-signed certificate and set up an HTTPS listener
# Hostname: DESKTOP-RM5C3F0
$cert = New-SelfSignedCertificate -DnsName 192.168.56.254 -CertStoreLocation "cert:\LocalMachine\My"
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"192.168.56.254`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"
Export-Certificate -Cert $cert -FilePath C:\users\student\winrm-cert.cer

# Create a firewall rule to allow WinRM HTTPS inbound
New-NetFirewallRule -DisplayName "Allow WinRM HTTPS" -Direction Inbound -LocalPort 5986 -RemoteAddress 192.168.56.20 -Protocol TCP -Action Allow

# Configure TrustedHosts
# Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.56.20,192.168.56.254" -Force


Set LocalAccountTokenFilterPolicy
New-ItemProperty -Name LocalAccountTokenFilterPolicy -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -PropertyType DWord -Value 1 -Force

# Set Execution Policy to Unrestricted
# Set-ExecutionPolicy Unrestricted -Force
Set-ExecutionPolicy RemoteSigned -Force

# Restart the WinRM service
# Restart-Service WinRM
# Check the status and start the service if it's not running
if ((Get-Service -Name WinRM).Status -ne 'Running') {
    Start-Service -Name WinRM
} else {
    Restart-Service -Name WinRM
}

# Delete HTTP listener, if any
# winrm delete winrm/config/Listener?Address=*+Transport=HTTP


List the WinRM listeners
winrm enumerate winrm/config/Listener
