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