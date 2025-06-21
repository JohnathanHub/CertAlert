# CertAlert

**SSL Certificate Monitoring System for Ubuntu**

CertAlert is a comprehensive SSL certificate monitoring solution that automatically tracks certificate expiration dates and sends email notifications before certificates expire. Written in bash and using anachron for daily expiration date check allows for running on personal machines/spot instances without complications.

### Installation

```bash
wget https://raw.githubusercontent.com/JohnathanHub/CertAlert/refs/heads/main/instalator.sh
sudo chmod +x instalator.sh
sudo ./instalator.sh
```
Please make sure that you have postfix configured on the machine.

### Basic Usage

After installation, use the `Certalert` command:

```bash
# Monitor a website certificate
Certalert -u example.com admin@company.com

# Monitor a local certificate file
Certalert -f /path/to/certificate.pem admin@company.com

# Remove monitoring for a certificate
Certalert -rm SERIAL_NUMBER admin@company.com

# Show help
Certalert --help
```
### Notification Schedule

- **30 days before expiration** - First warning
- **14 days before expiration** - Second warning  
- **7 days before expiration** - Third warning
- **1 day before expiration** - Final warning
- **On expiration day** - Certificate expired notification (monitoring file deleted)

## Uninstallation

To completely remove CertAlert:

```bash
sudo /var/lib/CertAlert/uninstall.sh
```

This removes:
- All scripts and monitoring files
- Cron/anacron jobs
- System command alias
- Installation directory

**Note:** Installed packages (openssl, mailutils, anacron) are not removed.

## Requirements

- **OS**: Ubuntu 18.04+ (may work on other Debian-based distributions)
- **Privileges**: Root access required for installation and operation
- **Dependencies**: openssl, mailutils, anacron (automatically installed)
- **Mail**: Working mail system for notifications
