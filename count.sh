#!/usr/bin/env bash

count_effective_lines() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "Błąd: Plik '$file' nie istnieje."
        return 1
    fi

    local count=$(grep -v '^$' "$file" | grep -v '^[[:space:]]*#' | wc -l)
    echo "File: $file [$count]"
}

count_effective_lines "findclean.sh"
count_effective_lines "log_analyzer.sh"
count_effective_lines "notatnik.sh"
