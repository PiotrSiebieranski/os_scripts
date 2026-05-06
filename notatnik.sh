#!/bin/bash

WERSJA="1.0"
AUTOR="Piotr Siebierański"
KATALOG_NOTATEK="$HOME/.notatnik"
WYNIK_TMP=$(mktemp)
mkdir -p "$KATALOG_NOTATEK"

pokaz_pomoc() {
    echo "Użycie: $(basename "$0") [OPCJE]"
    echo "  -d KATALOG   Katalog z notatkami (domyślnie: ~/.notatnik)"
    echo "  -v           Wersja i autor"
    echo "  -h           Pomoc"
}

cleanup() { rm -f "$WYNIK_TMP"; }
trap cleanup EXIT

while getopts "d:vh" opt; do
    case "$opt" in
        d) KATALOG_NOTATEK="$OPTARG"; mkdir -p "$KATALOG_NOTATEK" ;;
        v) echo "notatnik v${WERSJA} – ${AUTOR}"; exit 0 ;;
        h) pokaz_pomoc; exit 0 ;;
        *) pokaz_pomoc; exit 1 ;;
    esac
done

lista_notatek() {
    PLIKI=("$KATALOG_NOTATEK"/*.txt)
    [[ ! -e "${PLIKI[0]}" ]] && { dialog --msgbox "Brak notatek." 6 40; return 1; }
    OPCJE=()
    for PLIK in "${PLIKI[@]}"; do
        NAZWA=$(basename "$PLIK" .txt)
        ROZMIAR=$(wc -c < "$PLIK")
        OPCJE+=("$PLIK" "$NAZWA  [${ROZMIAR}B]")
    done
    dialog --title "Lista notatek" --menu "Wybierz notatkę:" 20 70 10 "${OPCJE[@]}" 2>"$WYNIK_TMP" || return 1
    cat "$WYNIK_TMP"
}

dodaj_notatke() {
    dialog --title "Nowa notatka" --inputbox "Podaj tytuł:" 8 50 "" 2>"$WYNIK_TMP" || return
    TYTUL=$(cat "$WYNIK_TMP" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    [[ -z "$TYTUL" ]] && { dialog --msgbox "Tytuł nie może być pusty!" 6 40; return; }
    PLIK="$KATALOG_NOTATEK/${TYTUL}_$(date +%Y%m%d).txt"
    dialog --title "Treść: $TYTUL" --editbox /dev/null 20 70 2>"$WYNIK_TMP" || return
    cat "$WYNIK_TMP" > "$PLIK"
    dialog --msgbox "Notatka '$TYTUL' zapisana." 6 50
}

podglad_notatki() {
    WYBRANY=$(lista_notatek) || return
    dialog --title "$(basename "$WYBRANY" .txt)" --textbox "$WYBRANY" 20 70
}

edytuj_notatke() {
    WYBRANY=$(lista_notatek) || return
    dialog --title "Edycja: $(basename "$WYBRANY" .txt)" --editbox "$WYBRANY" 20 70 2>"$WYNIK_TMP" || return
    cat "$WYNIK_TMP" > "$WYBRANY"
    dialog --msgbox "Notatka zaktualizowana." 6 40
}

usun_notatke() {
    WYBRANY=$(lista_notatek) || return
    NAZWA=$(basename "$WYBRANY" .txt)
    dialog --title "Potwierdzenie" --yesno "Usunąć notatkę '$NAZWA'?" 7 50 || return
    rm -f "$WYBRANY"
    dialog --msgbox "Notatka '$NAZWA' usunięta." 6 50
}

szukaj_notatek() {
    dialog --title "Szukaj" --inputbox "Podaj szukaną frazę:" 8 50 "" 2>"$WYNIK_TMP" || return
    FRAZA=$(cat "$WYNIK_TMP")
    [[ -z "$FRAZA" ]] && return
    WYNIKI=$(grep -ril "$FRAZA" "$KATALOG_NOTATEK" 2>/dev/null)
    if [[ -z "$WYNIKI" ]]; then
        dialog --msgbox "Nie znaleziono: '$FRAZA'" 7 50
    else
        PODGLAD=""
        while IFS= read -r PLIK; do
            PODGLAD+="=== $(basename "$PLIK" .txt) ===\n"
            PODGLAD+="$(grep -i --color=never "$FRAZA" "$PLIK")\n\n"
        done <<< "$WYNIKI"
        echo -e "$PODGLAD" > "$WYNIK_TMP"
        dialog --title "Wyniki: '$FRAZA'" --textbox "$WYNIK_TMP" 20 70
    fi
}

while true; do
    dialog --title "Notatnik v${WERSJA}" --menu "Wybierz opcję:" 16 50 6 \
        1 "Dodaj nową notatkę" \
        2 "Przeglądaj notatki" \
        3 "Edytuj notatkę" \
        4 "Usuń notatkę" \
        5 "Szukaj w notatkach" \
        6 "Wyjście" 2>"$WYNIK_TMP"
    [[ $? -ne 0 ]] && break
    case $(cat "$WYNIK_TMP") in
        1) dodaj_notatke ;;
        2) podglad_notatki ;;
        3) edytuj_notatke ;;
        4) usun_notatke ;;
        5) szukaj_notatek ;;
        6) break ;;
    esac
done

clear && echo "Do widzenia!"
