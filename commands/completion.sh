#!/usr/bin/env bash
# DESCRIPTION: output shell completion script (source or eval to enable tab completion)

KONBINI_CMD_NAME="$(basename "$KONBINI_ROOT/konbini")"

SHELL_TYPE="${1:-bash}"

case "$SHELL_TYPE" in
    bash)
        cat <<EOF
_${KONBINI_CMD_NAME}_complete() {
    local cur="\${COMP_WORDS[\$COMP_CWORD]}"
    local completions
    # Use \${COMP_WORDS[0]} so wrapper scripts (which may inject flags like
    # --custom-commands-dir) are invoked rather than the raw konbini binary.
    completions=\$("\${COMP_WORDS[0]}" --complete-bash "\$COMP_CWORD" "\${COMP_WORDS[@]}" 2>/dev/null)
    COMPREPLY=(\$(compgen -W "\$completions" -- "\$cur"))
    return 0
}
complete -F _${KONBINI_CMD_NAME}_complete "$KONBINI_CMD_NAME"
EOF
        ;;
    zsh)
        cat <<EOF
_${KONBINI_CMD_NAME}_complete() {
    local completions
    # Use \${words[1]} (the invoked command) so wrapper scripts are called.
    completions=\$("\${words[1]}" --complete-bash "\$CURRENT" "\${words[@]}" 2>/dev/null)
    local -a items
    while IFS= read -r line; do
        [[ -n "\$line" ]] && items+=("\$line")
    done <<< "\$completions"
    compadd -a items
}
compdef _${KONBINI_CMD_NAME}_complete "$KONBINI_CMD_NAME"
EOF
        ;;
    *)
        echo "Error: unsupported shell '$SHELL_TYPE'. Supported: bash, zsh" >&2
        exit 1
        ;;
esac
