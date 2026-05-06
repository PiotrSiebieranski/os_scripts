#!/bin/bash

WERSJA="1.0"
AUTOR="Student"
KATALOG="$HOME"
ROZSZERZENIE=""
MIN_ROZMIAR=""
MAX_ROZMIAR=""
WIEK_DNI=""
TRYB_USUN=0
TRYB_ARCHIWUM=0
TRYB_STATS=0
PLIK_WYJSCIA=""
PUSTY=0

pokaz_pomoc() {
    echo "Użycie: $(basename "$0") [OPCJE]"
    echo "  -d KATALOG    Katalog do przeszukania (domyślnie: \$HOME)"
    echo "  -e ROZSZ.     Filtruj po rozszerzeniu (np. txt, log)"
    echo "  -m MB         Minimalny rozmiar w MB"
    echo "  -M MB         Maksymalny rozmiar w MB"
    echo "  -w DNI        Pliki niezmieniane od X dni"
    echo "  -p            Tylko puste pliki"
    echo "  -u            Usuń znalezione pliki (z potwierdzeniem)"
    echo "  -a            Archiwizuj wyniki do tar.gz"
    echo "  -S            Pokaż statystyki"
    echo "  -o PLIK       Zapisz listę do pliku"
    echo "  -v            Wersja i autor"
    echo "  -h            Pomoc"
}

pokaz_statystyki() {
    local liczba rozmiar_sum
    liczba=$(echo "$1" | grep -c .)
    rozmiar_sum=$(echo "$1" | xargs -d '\n' du -sch 2>/dev/null | tail -1 | cut -f1)
    echo "========================================"
    echo "  Liczba plików : $liczba"
    echo "  Łączny rozmiar: ${rozmiar_sum:-0}"
    echo "========================================"
}

while getopts "d:e:m:M:w:puaSo:vh" opt; do
    case "$opt" in
        d) KATALOG="$OPTARG" ;;
        e) ROZSZERZENIE="$OPTARG" ;;
        m) MIN_ROZMIAR="$OPTARG" ;;
        M) MAX_ROZMIAR="$OPTARG" ;;
        w) WIEK_DNI="$OPTARG" ;;
        p) PUSTY=1 ;;
        u) TRYB_USUN=1 ;;
        a) TRYB_ARCHIWUM=1 ;;
        S) TRYB_STATS=1 ;;
        o) PLIK_WYJSCIA="$OPTARG" ;;
        v) echo "findclean v${WERSJA} – ${AUTOR}"; exit 0 ;;
        h) pokaz_pomoc; exit 0 ;;
        *) pokaz_pomoc; exit 1 ;;
    esac
done

[[ ! -d "$KATALOG" ]] && { echo "Błąd: '$KATALOG' nie istnieje." >&2; exit 1; }
[[ -n "$MIN_ROZMIAR" && ! "$MIN_ROZMIAR" =~ ^[0-9]+$ ]] && { echo "Błąd: rozmiar musi być liczbą." >&2; exit 1; }
[[ -n "$WIEK_DNI"    && ! "$WIEK_DNI"    =~ ^[0-9]+$ ]] && { echo "Błąd: dni musi być liczbą."    >&2; exit 1; }

FIND_CMD=(find "$KATALOG" -type f)
[[ -n "$ROZSZERZENIE" ]] && FIND_CMD+=(-name "*.${ROZSZERZENIE}")
[[ -n "$MIN_ROZMIAR"  ]] && FIND_CMD+=(-size +"${MIN_ROZMIAR}M")
[[ -n "$MAX_ROZMIAR"  ]] && FIND_CMD+=(-size -"${MAX_ROZMIAR}M")
[[ -n "$WIEK_DNI"     ]] && FIND_CMD+=(-mtime +"${WIEK_DNI}")
[[ "$PUSTY" -eq 1     ]] && FIND_CMD+=(-empty)

echo "========================================"
echo "  FINDCLEAN – wyszukiwanie plików"
echo "  Katalog : $KATALOG"
[[ -n "$ROZSZERZENIE" ]] && echo "  Typ     : *.${ROZSZERZENIE}"
[[ -n "$MIN_ROZMIAR"  ]] && echo "  Min.    : ${MIN_ROZMIAR} MB"
[[ -n "$MAX_ROZMIAR"  ]] && echo "  Maks.   : ${MAX_ROZMIAR} MB"
[[ -n "$WIEK_DNI"     ]] && echo "  Wiek    : >${WIEK_DNI} dni"
echo "========================================"

WYNIKI=$("${FIND_CMD[@]}" 2>/dev/null)

if [[ -z "$WYNIKI" ]]; then
    echo "  Brak plików spełniających kryteria."; exit 0
fi

echo "$WYNIKI"

[[ "$TRYB_STATS"   -eq 1 ]] && pokaz_statystyki "$WYNIKI"
[[ -n "$PLIK_WYJSCIA"    ]] && { echo "$WYNIKI" > "$PLIK_WYJSCIA"; echo "  Zapisano do: $PLIK_WYJSCIA"; }

if [[ "$TRYB_ARCHIWUM" -eq 1 ]]; then
    ARCHIWUM="findclean_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo "$WYNIKI" | xargs tar -czf "$ARCHIWUM" 2>/dev/null
    echo "  Zarchiwizowano do: $ARCHIWUM"
fi

if [[ "$TRYB_USUN" -eq 1 ]]; then
    read -rp "  Czy usunąć znalezione pliki? [t/N]: " ODPOWIEDZ
    if [[ "$ODPOWIEDZ" =~ ^[tT]$ ]]; then
        echo "$WYNIKI" | xargs rm -f 2>/dev/null && echo "  Pliki usunięte."
    else
        echo "  Anulowano."
    fi
fi
