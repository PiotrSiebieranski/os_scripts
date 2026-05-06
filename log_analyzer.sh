#!/bin/bash

WERSJA="1.0"
AUTOR="Student"
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
  echo "  ERROR         : $(grep -ci 'error' "$1" 2>/dev/null)"
  echo "  WARN          : $(grep -ci 'warn'  "$1" 2>/dev/null)"
  echo "  INFO          : $(grep -ci 'info'  "$1" 2>/dev/null)"
  echo "========================================"
}

while getopts "f:l:n:o:s:rSvh" opt; do
  case "$opt" in
    f) PLIK_LOGU="$OPTARG" ;;
    l) POZIOM=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]') ;;
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
  WARN)  WZORZEC="warn"  ;;
  INFO)  WZORZEC="info"  ;;
  ALL)   WZORZEC="error\|warn\|info" ;;
  *)     echo "Błąd: nieznany poziom '$POZIOM'. Użyj: ERROR, WARN, INFO, ALL." >&2; exit 1 ;;
esac

[[ "$STATYSTYKI" -eq 1 ]] && pokaz_statystyki "$PLIK_LOGU"

echo "========================================"
echo "  WYNIKI – ostatnie $LICZBA wpisów [${POZIOM}]"
[[ -n "$SZUKANA" ]] && echo "  Fraza: $SZUKANA"
echo "========================================"

[[ "$ODWROTNIE" -eq 1 ]] && SORT_OPT="" || SORT_OPT="-r"

WYNIKI=$(
  grep -i "$WZORZEC" "$PLIK_LOGU" \
    | { [[ -n "$SZUKANA" ]] && grep -i "$SZUKANA" || cat; } \
    | sort $SORT_OPT \
    | tail -n "$LICZBA" \
    | sed \
    -e 's/error/ERROR/gI' \
    -e 's/warning\|warn/WARN/gI' \
    -e 's/[[:space:]]\+/ /g' \
    -e 's/^[[:space:]]*//' \
    -e 's/[[:space:]]*$//'
  )

  if [[ -z "$WYNIKI" ]]; then
    echo "  Brak wyników dla podanych kryteriów."
  else
    echo "$WYNIKI"
    echo ""
    echo "  Znaleziono: $(echo "$WYNIKI" | wc -l) linii"
  fi

  if [[ -n "$PLIK_WYJSCIA" ]]; then
    echo "$WYNIKI" > "$PLIK_WYJSCIA"
    echo "  Zapisano do: $PLIK_WYJSCIA"
  fi

  echo "========================================"
