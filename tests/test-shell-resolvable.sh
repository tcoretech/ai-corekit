#!/usr/bin/env bash
# Every command called in command position must resolve to something.
#
# Exists because a refactor deleted a function while leaving its call site in a
# branch no test reached: `corekit managed-update apply` aborted with exit 127
# after doing twenty minutes of expensive work. `bash -n` cannot see it (the
# syntax is valid) and shellcheck does not report undefined functions.
#
# Approach: build an inventory of every function defined anywhere in the
# repository's shell files, then check that each bare identifier used in command
# position resolves to that inventory, a shell builtin, or an executable on PATH.
# Repository-wide rather than per-file, because these scripts source their
# helpers at runtime; the bug worth catching is "defined nowhere at all".
#
# Limits worth knowing:
#  - It only flags a command alone on its own line with no arguments. A deleted
#    function called as `foo "$bar"` still slips through.
#  - It cannot see a command assembled at runtime.
#  - It resolves names against the PATH of whatever runs it, so a script naming
#    a host-only tool will fail on a CI runner that lacks it.
# It does catch the case above, which is the one that bit us.
set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0

# Keywords of interpreters embedded as quoted programs (awk, sed). The
# quote-tracking below catches most such blocks, but an apostrophe inside an
# earlier double-quoted shell string breaks quote parity for the rest of the
# file. These words are never shell commands, so excluding them costs no signal.
EMBEDDED_KEYWORDS='next|getline|delete|nextfile|END|BEGIN'

KEYWORDS='if|then|else|elif|fi|for|while|until|do|done|case|esac|in|function|select|time|coproc|return|break|continue|exit|local|declare|readonly|export|unset|shift|eval|exec|source|trap|set|shopt|read|echo|printf|test|true|false|cd|pwd|umask|wait|kill|jobs|command|builtin|mapfile|readarray|let|getopts|hash|type|alias|dirs|popd|pushd|enable|history|bind|fc|caller|compgen|complete|ulimit|times'

shell_files() {
  find "$PROJECT_ROOT/lib" "$PROJECT_ROOT/services" "$PROJECT_ROOT/tests" -name '*.sh' -type f 2>/dev/null \
    | grep -vE '/(build|repo|node_modules)/'
  printf '%s\n' "$PROJECT_ROOT/corekit.sh" "$PROJECT_ROOT/install.sh"
}

# Strip comments and heredoc bodies, both of which contain prose that looks like
# commands. Heredocs are skipped from their opener to their terminator.
strip_noise() {
  awk '
    /^[[:space:]]*#/ { next }
    match($0, /<<-?[[:space:]]*'"'"'?"?[A-Za-z_][A-Za-z0-9_]*'"'"'?"?/) {
      tag = substr($0, RSTART, RLENGTH)
      gsub(/^<<-?[[:space:]]*['"'"'"]?|['"'"'"]?$/, "", tag)
      inheredoc = 1; hdtag = tag; print ""; next
    }
    inheredoc { if ($0 ~ "^[[:space:]]*" hdtag "[[:space:]]*$") inheredoc = 0; print ""; next }
    { sub(/[[:space:]]#[^"'"'"']*$/, ""); print }
  ' "$1"
}

echo "Building function inventory..."
INVENTORY="$(mktemp)"; trap 'rm -f "$INVENTORY"' EXIT
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  { strip_noise "$f" \
    | grep -oE '^[[:space:]]*(function[[:space:]]+)?[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)' \
    | grep -oE '[a-zA-Z_][a-zA-Z0-9_]*' | grep -vxE 'function'; } || true
done < <(shell_files) | sort -u > "$INVENTORY"
echo "  $(wc -l < "$INVENTORY") functions defined across the repository"
echo

while IFS= read -r file; do
  [[ -f "$file" ]] || continue
  rel="${file#"$PROJECT_ROOT"/}"
  unresolved=()
  while IFS= read -r word; do
    [[ -z "$word" ]] && continue
    [[ "$word" =~ ^($KEYWORDS)$ ]] && continue
    [[ "$word" =~ ^($EMBEDDED_KEYWORDS)$ ]] && continue
    grep -qxF "$word" "$INVENTORY" && continue
    command -v "$word" >/dev/null 2>&1 && continue
    unresolved+=("$word")
  done < <(
    { strip_noise "$file" | awk '
        # A bare word on its own line is only a command if the previous line did
        # not continue onto it. Array literals and wrapped argument lists put
        # bare words on their own lines too, and those are operands.
        function trim(x) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", x); return x }
        {
          # Embedded programs (awk, sed, python) are passed as single-quoted
          # strings spanning many lines. Their keywords are not shell commands.
          q = gsub(/'"'"'/, "'"'"'", $0)
          if (inquote) { if (q % 2 == 1) inquote = 0; next }
          if (q % 2 == 1) { inquote = 1; next }
          line = $0
          if (cont) { cont = (line ~ /\\$/) || (open > 0); next_is_operand = 1 }
          else      { next_is_operand = 0 }
          n = gsub(/\(/, "(", line); m = gsub(/\)/, ")", line)
          open += n - m; if (open < 0) open = 0
          if (!next_is_operand && open == 0 && trim($0) ~ /^[a-zA-Z_][a-zA-Z0-9_]*$/)
            print trim($0)
          if ($0 ~ /\\$/) cont = 1
        }
      ' | sort -u; } || true
  )
  if (( ${#unresolved[@]} > 0 )); then
    echo "FAIL  $rel"
    printf '        unresolved: %s\n' "${unresolved[@]}"
    FAILURES=$((FAILURES + ${#unresolved[@]}))
  fi
done < <(shell_files | sort)

if (( FAILURES > 0 )); then
  echo
  echo "$FAILURES unresolved command(s). A call with no definition aborts the script at runtime."
  exit 1
fi
echo "All commands in command position resolve."
