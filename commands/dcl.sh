#!/usr/bin/env bash
# DESCRIPTION: docker compose logs [-f] [-t] [--no-follow] [-n lines] [name]

follow=true
tail_lines=""
service=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-follow)
            follow=false
            shift
            ;;
        -n|--tail)
            tail_lines="$2"
            shift 2
            ;;
        *)
            service="$1"
            shift
            ;;
    esac
done

args=()
[[ "$follow" == true ]] && args+=("-f")
args+=("-t")
[[ -n "$tail_lines" ]] && args+=("--tail" "$tail_lines")
[[ -n "$service" ]] && args+=("$service")

docker compose logs "${args[@]}"
