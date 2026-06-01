#!/bin/bash
set -e

# Ensure website directory exists
mkdir -p ./data/website

# Check if index.html exists, if not copy from templates
if [ ! -f "./data/website/index.html" ]; then
    if [ -f "./templates/landing-page.html" ]; then
        echo "Initializing website/index.html from template..."
        cp "./templates/landing-page.html" "./data/website/index.html"
    else
        echo "Warning: Template not found at ./templates/landing-page.html"
    fi
fi

# Render Caddyfile addons.
#
# Caddy itself substitutes {$VAR} placeholders at runtime, but only against the
# explicit env list in this service's docker-compose.yml. That allow-list is
# tightly scoped on purpose — the global .env.global contains secrets (API
# keys, SMTP passwords) we don't want to leak into the Caddy container.
#
# So addons that need values from .env.global (or any other corekit-managed
# scope) use a template pattern instead: drop *.conf.template into
# ./config/addons/, and this script renders them against the caller's exported
# environment with envsubst. Rendered output lives in ./data/addons-rendered/
# which Caddy mounts as /etc/caddy/addons.
#
# Plain *.conf files in ./config/addons/ are passed through unchanged for
# backward compatibility — they continue to rely on Caddy's runtime
# substitution (and therefore on whatever the compose env list exposes).
#
# Templates support shell default-value syntax for robustness when a variable
# is unset, e.g.:
#   ${MY_SERVICE_HOSTNAME:-disabled-my-service.invalid} { ... }
# An unset variable then renders to a placeholder dormant vhost instead of
# producing an empty site key that crashes Caddy's config parser.

render_addon_template() {
    local tmpl="$1" out="$2"

    # Defaults pass: for every ${VAR:-default} occurrence, if VAR is unset or
    # empty in the calling environment, export it with `default` so the
    # subsequent envsubst step substitutes it correctly. This loop is scoped
    # to a subshell when invoked so the exports don't bleed into the parent.
    while IFS= read -r match; do
        local var default
        var="${match#\$\{}"
        var="${var%%:-*}"
        default="${match#*:-}"
        default="${default%\}}"
        if [ -z "${!var:-}" ]; then
            export "$var=$default"
        fi
    done < <(grep -oE '\$\{[A-Z_][A-Z0-9_]*:-[^}]*\}' "$tmpl" || true)

    # Strip :-default suffixes so envsubst sees plain ${VAR} (envsubst itself
    # does not understand the default-value form).
    sed -E 's/\$\{([A-Z_][A-Z0-9_]*):-[^}]*\}/${\1}/g' "$tmpl" | envsubst > "$out"
}

RENDERED_DIR="./data/addons-rendered"
mkdir -p "$RENDERED_DIR"
# Clear stale output so removed/renamed templates disappear cleanly.
find "$RENDERED_DIR" -maxdepth 1 -name "*.conf" -type f -delete 2>/dev/null || true

shopt -s nullglob
templates=(./config/addons/*.conf.template)
plain_addons=(./config/addons/*.conf)
shopt -u nullglob

if [ ${#templates[@]} -gt 0 ]; then
    if ! command -v envsubst >/dev/null; then
        echo "Error: envsubst is required to render Caddy addon templates." >&2
        echo "       Install with: apt-get install gettext-base" >&2
        exit 1
    fi
    for tmpl in "${templates[@]}"; do
        out="$RENDERED_DIR/$(basename "$tmpl" .template)"
        echo "Rendering addon template: $(basename "$tmpl") -> $(basename "$out")"
        # Run in a subshell so per-template default exports don't leak forward.
        ( render_addon_template "$tmpl" "$out" )
    done
fi

for plain in "${plain_addons[@]}"; do
    out="$RENDERED_DIR/$(basename "$plain")"
    # A template-rendered file with the same final name wins.
    if [ ! -f "$out" ]; then
        cp "$plain" "$out"
    fi
done
