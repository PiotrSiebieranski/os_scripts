#!/usr/bin/env bash

WERSJA="1.2"
AUTOR="Piotr Siebierański"
KATALOG_NOTATEK="$HOME/.notatnik"
WYNIK_TMP=$(mktemp)
mkdir -p "$KATALOG_NOTATEK"
shopt -s nullglob
trap 'rm -f "$WYNIK_TMP"' EXIT

pokaz_pomoc() {
    echo "Użycie: $(basename "$0") [OPCJE]"
    echo "  -d KATALOG    Katalog z notatkami (domyślnie: ~/.notatnik)"
    echo "  -v            Wersja i autor"
    echo "  -h            Pomoc"
}

while getopts "d:vh" opt; do
    case "$opt" in
        d) KATALOG_NOTATEK="$OPTARG"; mkdir -p "$KATALOG_NOTATEK" ;;
        v) echo "notatnik v${WERSJA} – ${AUTOR}"; exit 0 ;;
        h) pokaz_pomoc; exit 0 ;;
        *) pokaz_pomoc; exit 1 ;;
    esac
done

lista_notatek() {
    local PLIKI=("$KATALOG_NOTATEK"/*.txt)
    [[ ${#PLIKI[@]} -eq 0 ]] && { dialog --msgbox "Brak notatek." 6 40 ; return 1; }
    local OPCJE=()
    for PLIK in "${PLIKI[@]}"; do
        OPCJE+=("$PLIK" "$(basename "$PLIK" .txt) [$(wc -c < "$PLIK")B]")
    done
    dialog --title "Lista notatek" --menu "Wybierz notatkę:" 20 70 10 \
        "${OPCJE[@]}" 2>"$WYNIK_TMP" </dev/tty >/dev/tty || return 1
    cat "$WYNIK_TMP"
}

dodaj_notatke() {
    dialog --title "Nowa notatka" --inputbox "Podaj tytuł (bez spacji):" 8 50 "" 2>"$WYNIK_TMP" || return
    local TYTUL; TYTUL=$(cat "$WYNIK_TMP" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    [[ -z "$TYTUL" ]] && { dialog --msgbox "Tytuł nie może być pusty!" 6 40; return; }
    local PLIK="$KATALOG_NOTATEK/${TYTUL}_$(date +%Y%m%d).txt"
    touch "$PLIK"
    dialog --title "Treść: $TYTUL" --editbox "$PLIK" 20 70 2>"$WYNIK_TMP" || { rm -f "$PLIK"; return; }
    cat "$WYNIK_TMP" > "$PLIK"
    dialog --msgbox "Notatka '$TYTUL' zapisana." 6 50
}

edytuj_notatke() {
    local WYBRANY; WYBRANY=$(lista_notatek) || return
    dialog --title "Edycja: $(basename "$WYBRANY" .txt)" --editbox "$WYBRANY" 22 75 2>"$WYNIK_TMP" || return
    cat "$WYNIK_TMP" > "$WYBRANY"
    dialog --msgbox "Notatka zaktualizowana." 6 40
}

usun_notatke() {
    local WYBRANY; WYBRANY=$(lista_notatek) || return
    local NAZWA; NAZWA=$(basename "$WYBRANY" .txt)
    dialog --title "Potwierdzenie" --yesno "Usunąć notatkę '$NAZWA'?" 7 55 || return
    rm -f "$WYBRANY"
    dialog --msgbox "Notatka '$NAZWA' usunięta." 6 50
}

szukaj_notatek() {
    dialog --title "Szukaj" --inputbox "Podaj szukaną frazę:" 8 50 "" 2>"$WYNIK_TMP" || return
    local FRAZA; FRAZA=$(cat "$WYNIK_TMP")
    [[ -z "$FRAZA" ]] && return
    local WYNIKI; WYNIKI=$(grep -ril "$FRAZA" "$KATALOG_NOTATEK" 2>/dev/null)
    [[ -z "$WYNIKI" ]] && { dialog --msgbox "Nie znaleziono: '$FRAZA'" 7 50; return; }
    local PODGLAD=""
    while IFS= read -r PLIK; do
        PODGLAD+="=== $(basename "$PLIK" .txt) ===\n$(grep -i "$FRAZA" "$PLIK")\n\n"
    done <<< "$WYNIKI"
    echo -e "$PODGLAD" > "$WYNIK_TMP"
    dialog --title "Wyniki dla: '$FRAZA'" --textbox "$WYNIK_TMP" 20 70
}

while true; do
    dialog --title "Notatnik v${WERSJA}" --cancel-label "Wyjście" \
        --menu "Menu główne:" 16 55 5 \
        1 "Dodaj nową notatkę"         \
        2 "Podgląd notatki"            \
        3 "Edytuj istniejącą notatkę"  \
        4 "Usuń notatkę"               \
        5 "Szukaj w treści notatek"    2>"$WYNIK_TMP" || break
    case $(cat "$WYNIK_TMP") in
        1) dodaj_notatke ;;
        2) WYBRANY=$(lista_notatek) && dialog --title "$(basename "$WYBRANY" .txt)" --textbox "$WYBRANY" 22 75 ;;
        3) edytuj_notatke ;;
        4) usun_notatke ;;
        5) szukaj_notatek ;;
    esac
done

clear; echo "Notatnik został zamknięty."
