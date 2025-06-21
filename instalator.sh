#!/bin/bash

# CertAlert Ubuntu Installer
# SSL Certificate Monitoring System Installer

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Installation directories
INSTALL_DIR="/var/lib/CertAlert"
SCRIPT_DIR="$INSTALL_DIR/skrypty"
MONITOR_DIR="$INSTALL_DIR/Monitorowane"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This installer must be run as root (use sudo)"
        exit 1
    fi
}

# Update package list
update_packages() {
    print_status "Updating package list..."
    apt-get update -qq
    print_success "Package list updated"
}

# Install required packages
install_dependencies() {
    print_status "Installing required dependencies..."
    
    # List of required packages
    PACKAGES=(
        "openssl"
        "mailutils"
	"postfix"
        "anacron"
        "curl"
        "wget"
    )
    
    for package in "${PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            print_status "Installing $package..."
            apt-get install -y "$package"
        else
            print_status "$package is already installed"
        fi
    done
    
    print_success "All dependencies installed"
}

# Create directory structure
create_directories() {
    print_status "Creating directory structure..."
    
    # Create main directories
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$SCRIPT_DIR"
    mkdir -p "$MONITOR_DIR"
    
    # Set appropriate permissions
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$SCRIPT_DIR"
    chmod 755 "$MONITOR_DIR"
    
    print_success "Directory structure created at $INSTALL_DIR"
}

# Create pobieracz.sh script
create_pobieracz() {
    print_status "Creating pobieracz.sh script..."
    
    cat > "$SCRIPT_DIR/pobieracz.sh" << 'EOF'
#!/bin/sh
if [ $(/usr/bin/id -u) -ne 0 ]; then
    echo "Not running as root"
    exit 1
fi
if [ "$1" = "--help" ]; then
    echo "-f [droga do pliku] - sprawdzenie daty wygaśnięcia certyfikatu znajdującego się na komputerze"
    echo "-u [URL] - sprawdzenie daty wygaśnięcia certyfikatu strony"
    echo "-rm [numer seryjny certyfikatu] - usunięcie powiadomień na podany adres dla danego certyfikatu"
    echo "Skrypt wymaga dokładnie 3 parametrów, [typ] [plik/URL/nr seryjny cert] [email]"
else
        if [ "$#" -ne 3 ]; then
                echo "Skrypt wymaga dokładnie 3 parametrów, [typ] [plik/URL] [email]"
                echo "(run $0 --help for help)"
                echo ""
                exit 0
        fi
        TypCert=$1
        Cert=$2
        Email=$3
        P=/var/lib/CertAlert/Monitorowane/
        if [ "$TypCert" = "-f" ]; then
		Snum=$(openssl x509 -in "$Cert" -noout -serial | cut -d= -f2)
		FileName="$P"notif-"$Email"-"$Snum".txt
                touch "$FileName"
                echo `openssl x509 -in "$Cert" -enddate -noout | cut -d= -f2` > "$FileName"
                echo "$Email" >> "$FileName"
                echo `openssl x509 -in "$Cert" -noout -subject | sed -n 's/.*CN = //p'`>> "$FileName"
                echo `openssl x509 -in "$Cert" -noout -issuer`>> "$FileName"
                echo "$Snum">> "$FileName"
                echo "Pomyślnie zapisano datę wygaśnięcia certyfikatu $Cert, powiadomienie zostanie wysłane na adres $Email na 30, 14, 7, oraz 1 dzień przed wygaśnięciem oraz w dniu wygaśnięcia" 
                exit 0
        fi
	if [ "$TypCert" = "-rm" ]; then
		Filename="$P"notif-"$Email"-"$2".txt
		rm $Filename 2>/dev/null && echo "Usunięto powiadomienie o ważności certyfikatu $2 dla adresu $Email" || echo "błąd usuwania, sprawdź poprawność parametrów"
		exit 0
	fi
        if [ "$TypCert" = "-u" ]; then
		Snum=$(echo | openssl s_client -showcerts -servername "$Cert" -connect "$Cert":443 2>/dev/null | openssl x509 -inform pem -noout -serial | cut -d= -f2)
		FileName="$P"notif-"$Email"-"$Snum".txt
		touch "$FileName"
                echo | openssl s_client -showcerts -servername "$Cert" -connect "$Cert":443 2>/dev/null | openssl x509 -inform pem -noout -enddate | cut -d= -f2 > "$FileName"                
		echo "$Email" >> "$FileName"
                echo | openssl s_client -showcerts -servername "$Cert" -connect "$Cert":443 2>/dev/null | openssl x509 -inform pem -noout -subject | sed -n 's/.*CN = //p'>> "$FileName"                
		echo | openssl s_client -showcerts -servername "$Cert" -connect "$Cert":443 2>/dev/null | openssl x509 -inform pem -noout -issuer>> "$FileName"
                echo | openssl s_client -showcerts -servername "$Cert" -connect "$Cert":443 2>/dev/null | openssl x509 -inform pem -noout -serial>> "$FileName"
                echo "Pomyślnie zapisano datę wygaśnięcia certyfikatu $Cert, powiadomienie zostanie wysłane na adres $Email na 30, 14, 7, oraz 1 dzień przed wygaśnięciem oraz w dniu wygaśnięcia"
                exit 0
        else
                echo "$TypCert nie jest akceptowaną wartością dla typu sprawdzanego certyfikatu"
		echo "(run $0 --help for help)"
                echo ""
                exit 0
        fi
fi
EOF
    
    chmod +x "$SCRIPT_DIR/pobieracz.sh"
    print_success "pobieracz.sh created and made executable"
}

# Create powiadamiacz.sh script
create_powiadamiacz() {
    print_status "Creating powiadamiacz.sh script..."
    
    cat > "$SCRIPT_DIR/powiadamiacz.sh" << 'EOF'
#!/bin/sh
if [ $(/usr/bin/id -u) -ne 0 ]; then
    echo "Not running as root"
    exit 0
fi
if  [ "$1" = "--help" ]; then
    echo "skrypt wymaga jednego parametru w formie drogi do pliku"
else
        if [ "$#" -ne 1 ]; then
                echo "skrypt wymaga jednego parametru w formie drogi do pliku"
                echo "run $0 --help for help"
                echo ""
                exit 0
        fi
        Droga=$1
        Data=$(head -n 1 "$Droga")
        Email=$(head -n 2 "$Droga" | tail -n 1)
        Subject=$(head -n 3 "$Droga" | tail -n 1)
        Issuer=$(head -n 4 "$Droga" | tail -n 1)
        Nser=$(head -n 5 "$Droga" | tail -n 1)
        ExpT=$(( ($(date -d "$Data" '+%s') - $(date '+%s')) / 86400 + 1))
        if [ "$ExpT" -le 0 ]; then
                echo "Informacje o certyfikacie:\n Ważny do: $Data\n Właściciel certyfikaru: $Subject\n Wydawca certyfikatu: $Issuer\n Numer seryjny: $Nser" | mail -aFrom:zdawacz@projekt.zit -s "Certyfikat $Nser certyfikujący $Subject wygasł" "$Email"
                rm "$1" 2>/dev/null
                exit 0
        elif [ "$ExpT" -eq 1 ]; then
                echo "Informacje o certyfikacie:\n Ważny do: $Data\n Właściciel certyfikaru: $Subject\n Wydawca certyfikatu: $Issuer\n Numer seryjny: $Nser" | mail -aFrom:zdawacz@projekt.zit -s "Certyfikat $Nser certyfikujący $Subject wygaśnie za jeden dzień" "$Email"
                exit 0
        elif [ "$ExpT" -eq 7 ]; then
                echo "Informacje o certyfikacie:\n Ważny do: $Data\n Właściciel certyfikaru: $Subject\n Wydawca certyfikatu: $Issuer\n Numer seryjny: $Nser" | mail -aFrom:zdawacz@projekt.zit -s "Certyfikat $Nser certyfikujący $Subject wygaśnie za $ExpT dni" "$Email"
                exit 0
        elif [ "$ExpT" -eq 14 ]; then
                echo "Informacje o certyfikacie:\n Ważny do: $Data\n Właściciel certyfikaru: $Subject\n Wydawca certyfikatu: $Issuer\n Numer seryjny: $Nser" | mail -aFrom:zdawacz@projekt.zit -s "Certyfikat $Nser certyfikujący $Subject wygaśnie za $ExpT dni" "$Email"
                exit 0
        elif [ "$ExpT" -eq 30 ]; then
                echo -e "Informacje o certyfikacie:\n Ważny do: $Data\n Właściciel certyfikaru: $Subject\n Wydawca certyfikatu: $Issuer\n Numer seryjny: $Nser" | mail -aFrom:zdawacz@projekt.zit -s "Certyfikat $Nser certyfikujący $Subject wygaśnie za $ExpT dni" "$Email"
                exit 0
        fi
fi
EOF
    
    chmod +x "$SCRIPT_DIR/powiadamiacz.sh"
    print_success "powiadamiacz.sh created and made executable"
}

# Create powtarzacz.sh script
create_powtarzacz() {
    print_status "Creating powtarzacz.sh script..."
    
    cat > "$SCRIPT_DIR/powtarzacz.sh" << 'EOF'
#!/bin/bash

SCRIPT_PATH="/var/lib/CertAlert/skrypty/powiadamiacz.sh"
CERT_DIR="/var/lib/CertAlert/Monitorowane"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Skrypt $SCRIPT_PATH nie istnieje."
  exit 1
fi

if [ ! -d "$CERT_DIR" ]; then
  echo "Folder $CERT_DIR nie istnieje."
  exit 1
fi

for cert_file in "$CERT_DIR"/*; do
  if [ -f "$cert_file" ]; then
    "$SCRIPT_PATH" "$cert_file"
  fi
done
EOF
    
    chmod +x "$SCRIPT_DIR/powtarzacz.sh"
    print_success "powtarzacz.sh created and made executable"
}

# Create system-wide alias
create_alias() {
    print_status "Creating system-wide alias 'Certalert'..."
    
    # Create alias script in /usr/local/bin
    cat > /usr/local/bin/Certalert << EOF
#!/bin/bash
sudo $SCRIPT_DIR/pobieracz.sh "\$@"
EOF
    
    chmod +x /usr/local/bin/Certalert
    
    print_success "Alias 'Certalert' created - accessible system-wide"
}

# Setup anacron job
setup_anacron() {
    print_status "Setting up daily anacron job..."
    
    # Check if /etc/anacron.d exists, if not use /etc/anacrontab
    if [ -d "/etc/anacron.d" ]; then
        # Create anacron job file in anacron.d directory
        cat > /etc/anacron.d/certalert << EOF
# Certificate Alert Daily Check
1       5       certalert.daily    $SCRIPT_DIR/powtarzacz.sh
EOF
        print_success "Anacron job created in /etc/anacron.d/certalert"
    else
        # Add job to main anacrontab file
        if ! grep -q "certalert.daily" /etc/anacrontab 2>/dev/null; then
            echo "# Certificate Alert Daily Check" >> /etc/anacrontab
            echo "1       5       certalert.daily    $SCRIPT_DIR/powtarzacz.sh" >> /etc/anacrontab
            print_success "Anacron job added to /etc/anacrontab"
        else
            print_warning "Anacron job already exists in /etc/anacrontab"
        fi
    fi
    
    # Also create a fallback cron job for systems without anacron
    if [ -d "/etc/cron.d" ]; then
        cat > /etc/cron.d/certalert << EOF
# Certificate Alert Daily Check - Fallback cron job
0 2 * * * root $SCRIPT_DIR/powtarzacz.sh >/dev/null 2>&1
EOF
        print_success "Fallback cron job created in /etc/cron.d/certalert"
    fi
    
    # Start and enable anacron service
    systemctl enable anacron 2>/dev/null || true
    systemctl start anacron 2>/dev/null || true
    
    print_success "Daily job scheduling configured"
}

# Configure mail system
configure_mail() {
    print_status "Configuring mail system..."
    
    print_warning "Mail system configuration required!"
    echo ""
    echo "To complete the setup, you need to configure your mail system."
    echo "The scripts use the 'mail' command to send notifications."
    echo ""
    echo "For a simple setup, you can:"
    echo "1. Install and configure postfix: sudo apt-get install postfix"
    echo "2. Or configure an external SMTP server in /etc/postfix/main.cf"
    echo "3. Or use msmtp as an alternative to postfix"
}

# Create uninstaller
create_uninstaller() {
    print_status "Creating uninstaller script..."
    
    cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

echo "CertAlert Uninstaller"
echo "====================="

# Remove anacron job from anacron.d if it exists
rm -f /etc/anacron.d/certalert

# Remove anacron job from anacrontab if it exists
if [ -f /etc/anacrontab ]; then
    sed -i '/certalert.daily/d' /etc/anacrontab
    sed -i '/Certificate Alert Daily Check/d' /etc/anacrontab
fi

# Remove cron job
rm -f /etc/cron.d/certalert

# Remove alias
rm -f /usr/local/bin/Certalert

# Remove installation directory
rm -rf /var/lib/CertAlert

echo "CertAlert has been completely removed from your system."
echo "Note: Installed packages (openssl, mailutils, anacron) were not removed."
EOF
    
    chmod +x "$INSTALL_DIR/uninstall.sh"
    print_success "Uninstaller created at $INSTALL_DIR/uninstall.sh"
}

# Main installation function
main() {
    echo ""
    echo "========================================="
    echo "    CertAlert Installation Script"
    echo "    SSL Certificate Monitor System"
    echo "========================================="
    echo ""
    
    check_root
    update_packages
    install_dependencies
    create_directories
    create_pobieracz
    create_powiadamiacz
    create_powtarzacz
    create_alias
    setup_anacron
    create_uninstaller
    configure_mail
    
    echo ""
    print_success "Installation completed successfully!"
    echo ""
    echo "========================================="
    echo "           INSTALLATION SUMMARY"
    echo "========================================="
    echo "Scripts installed in: $SCRIPT_DIR"
    echo "Monitor directory: $MONITOR_DIR"
    echo "Daily check: Configured via anacron"
    echo "Uninstaller: $INSTALL_DIR/uninstall.sh"
    echo ""
    echo "Use Certalert --help to see options"
    echo ""
    echo "Note: Configure your mail system to enable email notifications."
    echo "========================================="
}

# Run main installation
main "$@"