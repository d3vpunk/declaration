#!/bin/bash

set -euo pipefail

echo ""
echo "======================================"
echo "Woon/Werk Reiskosten Declaratie Wizard"
echo "======================================"
echo ""
echo "Deze wizard maakt die cronjob aan die elk uur checkt of je op de juiste gateway zit (dus op kantoor bent)"
echo "Het script zal elk uur op een willekeurig moment worden uitgevoerd."
echo "Het is belangrijk dat je die gateway_check.sh in die deze folder niet verplaatst naar een andere folder, anders zou de cronjob niet meer werken."
echo "In dat geval aub. opnieuw deze setup wizard uitvoeren."
echo "Alle velden zijn verplicht. Geef alsjeblieft de volgende informatie:"
echo

# Functie om verplichte input te vragen
vraag_verplicht() {
    local vraag="$1"
    local antwoord=""
    while [ -z "$antwoord" ]; do
        read -p "$vraag: " antwoord
        if [ -z "$antwoord" ]; then
            echo "Dit veld is verplicht. Probeer opnieuw."
        fi
    done
    echo "$antwoord"
}

# Bepaal het absolute pad naar het script
script_pad="$(cd "$(dirname "$0")" && pwd)/gateway_check.sh"

# Parameters opvragen
voornaam=$(vraag_verplicht "Voornaam")
achternaam=$(vraag_verplicht "Achternaam")
kilometers=$(vraag_verplicht "Kilometers (heen + terug)")
woonplaats=$(vraag_verplicht "Woonplaats")
email=$(vraag_verplicht "E-mailadres")

# Genereer een willekeurige minuut voor het cron schema
random_minuut=$((RANDOM % 60))

# Cron schema (elk uur op een willekeurige minuut)
cron_schema="$random_minuut * * * *"

# Cron job commando samenstellen
cron_cmd="$cron_schema $script_pad firstname=\"$voornaam\" lastname=\"$achternaam\" kilometers=$kilometers location=\"$woonplaats\" email=\"$email\""

# Toon de cron job
echo
echo "Hier is je cron job (wordt elk uur op minuut $random_minuut uitgevoerd):"
echo "$cron_cmd"
echo

# Functie om crontab te updaten of nieuwe entry toe te voegen
update_crontab() {
    local tempfile=$(mktemp)
    crontab -l > "$tempfile" 2>/dev/null || true
    if grep -q "$script_pad" "$tempfile"; then
        # Gebruik een ander scheidingsteken voor sed om problemen met paden te voorkomen
        sed -i.bak "\|$script_pad|c\\$cron_cmd" "$tempfile"
        if [ $? -ne 0 ]; then
            echo "Er is een fout opgetreden bij het bijwerken van de bestaande cron job."
            return 1
        fi
        echo "Bestaande cron job bijgewerkt."
    else
        echo "$cron_cmd" >> "$tempfile"
        echo "Nieuwe cron job toegevoegd."
    fi
    if crontab "$tempfile"; then
        echo "Crontab succesvol bijgewerkt."
    else
        echo "Er is een fout opgetreden bij het bijwerken van de crontab."
        return 1
    fi
    rm "$tempfile"
}

# Bevestig en update crontab
while true; do
    read -p "Wil je deze job toevoegen of bijwerken in je crontab? (j/n) " bevestig
    case $bevestig in
        [Jj]* )
            if update_crontab; then
                echo "Cron job succesvol toegevoegd of bijgewerkt!"
                break
            else
                echo "Er is een probleem opgetreden. Wil je het opnieuw proberen? (j/n)"
                read opnieuw
                if [[ $opnieuw != [Jj]* ]]; then
                    echo "Wizard wordt afgesloten zonder wijzigingen."
                    exit 1
                fi
            fi
            ;;
        [Nn]* )
            echo "Cron job is niet toegevoegd of bijgewerkt. Je kunt het later handmatig doen als je wilt."
            break
            ;;
        * ) echo "Antwoord alsjeblieft met 'j' of 'n'.";;
    esac
done

echo
echo "Setup voltooid!"
echo "Je kunt je crontab altijd bewerken met het commando: crontab -e of deze setup wizard opnieuw uitvoeren (cronjob wordt niet dubbel aangemaakt)"
echo
echo "Bedankt en werk ze!"