#!/usr/bin/env bash
# DESCRIPTION: output shell completion script (source or eval to enable tab completion)

KONBINI_CMD_NAME="$(basename "$KONBINI_ROOT/konbini")"

SHELL_TYPE="${1:-bash}"

case "$SHELL_TYPE" in
    bash)
        cat <<EOF
_${KONBINI_CMD_NAME}_complete() {
    local cur="\${COMP_WORDS[\$COMP_CWORD]}"
    local path_cur="\$cur"
    local completions

    # Explicit path prefixes use Readline's native file completion. Keeping
    # this in the shell makes it independent of the preceding konbini command.
    if [ "\$cur" = "~" ]; then
        COMPREPLY=("~/")
        compopt -o filenames -o nospace
        return 0
    fi
    case "\$path_cur" in
        \"*|\'*) path_cur="\${path_cur:1}" ;;
    esac
    case "\$path_cur" in
        ./*|../*|/*|\~*)
            COMPREPLY=()
            compopt -o default
            return 0
            ;;
    esac

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
    local cur="\$PREFIX"
    local completions

    # Let zsh handle paths natively, regardless of the preceding command.
    case "\$cur" in
        ./*|../*|/*|\~*)
            _files
            return
            ;;
    esac

    # Use \${words[1]} (the invoked command) so wrapper scripts are called.
    completions=\$("\${words[1]}" --complete-bash "\$((CURRENT - 1))" "\${words[@]}" 2>/dev/null)
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
