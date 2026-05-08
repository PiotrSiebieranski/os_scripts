#!/usr/bin/env bash

# Ten skrypt to narzędzie do analizy plików logów systemowych. Pozwala na
# filtrowanie wpisów według poziomu logowania (ERROR, WARN, INFO), wyszukiwanie
# konkretnych fraz, generowanie statystyk oraz zapisywanie wyników do pliku.

WERSJA="1.1"
AUTOR="Piotr Siebierański"
PLIK_LOGU="/var/log/syslog"
POZIOM="ALL"
LICZBA=20
PLIK_WYJSCIA=""
SZUKANA=""
ODWROTNIE=0
STATYSTYKI=0

pokaz_pomoc() {
  echo "Użycie: $(basename "$0") [OPCJE]"
  echo "  -f PLIK      Plik logu (domyślnie: /var/log/syslog)"
  echo "  -l POZIOM    Poziom: ERROR, WARN, INFO, ALL (domyślnie: ALL)"
  echo "  -n LICZBA    Liczba wyników (domyślnie: 20)"
  echo "  -o PLIK      Zapisz wyniki do pliku"
  echo "  -s FRAZA     Szukaj frazy w wynikach"
  echo "  -r           Odwróć kolejność (najstarsze pierwsze)"
  echo "  -S           Pokaż statystyki"
  echo "  -v           Wersja i autor"
  echo "  -h           Pomoc"
}

pokaz_statystyki() {
  echo "========================================"
  echo "  STATYSTYKI: $(basename "$1")"
  echo "  Łącznie linii : $(wc -l < "$1")"
  echo "  ERROR         : $(grep -Ei 'error' "$1" | wc -l)"
  echo "  WARN          : $(grep -Ei 'warn|warning' "$1" | wc -l)"
  echo "  INFO          : $(grep -Ei 'info' "$1" | wc -l)"
  echo "========================================"
}

while getopts "f:l:n:o:s:rSvh" opt; do
  case "$opt" in
    f) PLIK_LOGU="$OPTARG" ;;
    l) POZIOM=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]' ) ;;
    n) LICZBA="$OPTARG" ;;
    o) PLIK_WYJSCIA="$OPTARG" ;;
    s) SZUKANA="$OPTARG" ;;
    r) ODWROTNIE=1 ;;
    S) STATYSTYKI=1 ;;
    v) echo "loganalyzer v${WERSJA} – ${AUTOR}"; exit 0 ;;
    h) pokaz_pomoc; exit 0 ;;
    *) pokaz_pomoc; exit 1 ;;
  esac
done

[[ ! -f "$PLIK_LOGU" ]] && { echo "Błąd: plik '$PLIK_LOGU' nie istnieje." >&2; exit 1; }
[[ ! "$LICZBA" =~ ^[0-9]+$ ]] && { echo "Błąd: -n musi być liczbą." >&2; exit 1; }

case "$POZIOM" in
  ERROR) WZORZEC="error" ;;
  WARN)  WZORZEC="warn|warning" ;;
  INFO)  WZORZEC="info" ;;
  ALL)   WZORZEC=".*" ;;
  *)     echo "Błąd: nieznany poziom '$POZIOM'. Użyj: ERROR, WARN, INFO, ALL." >&2; exit 1 ;;
esac

[[ "$STATYSTYKI" -eq 1 ]] && pokaz_statystyki "$PLIK_LOGU"

echo "========================================"
echo "  WYNIKI – ostatnie $LICZBA wpisów [${POZIOM}]"
[[ -n "$SZUKANA" ]] && echo "  Fraza: $SZUKANA"
echo "========================================"

if [[ "$ODWROTNIE" -eq 1 ]]; then
    WYNIKI=$(grep -Ei "$WZORZEC" "$PLIK_LOGU" | { [[ -n "$SZUKANA" ]] && grep -Ei "$SZUKANA" || cat; } | head -n "$LICZBA")
else
    WYNIKI=$(grep -Ei "$WZORZEC" "$PLIK_LOGU" | { [[ -n "$SZUKANA" ]] && grep -Ei "$SZUKANA" || cat; } | tail -n "$LICZBA")
fi

WYNIKI_FORMATTED=$(echo "$WYNIKI" | sed \
    -e 's/error/ERROR/gI' \
    -e 's/warning/WARN/gI' \
    -e 's/warn/WARN/gI' \
    -e 's/[[:space:]]\+/ /g' \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]*$//')

if [[ -z "$WYNIKI" ]]; then
  echo "  Brak wyników dla podanych kryteriów."
else
  echo "$WYNIKI_FORMATTED"
  echo ""
  echo "  Znaleziono: $(echo "$WYNIKI" | grep -v '^$' | wc -l) linii"
fi

if [[ -n "$PLIK_WYJSCIA" && -n "$WYNIKI" ]]; then
  echo "$WYNIKI_FORMATTED" > "$PLIK_WYJSCIA"
  echo "  Zapisano do: $PLIK_WYJSCIA"
fi

echo "========================================"
