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
        P=/var/lib/CertAlert/Monitorowane
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