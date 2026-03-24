#!/usr/bin/env bash
# ZooBot CLI Wrapper - fully self-locating, uses caller's actual HOME
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [ "${SOURCE#/}" = "$SOURCE" ] && SOURCE="$DIR/$SOURCE"
done
DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
INSTALL_HOME="$(cd "$DIR/.." && pwd)"
export ZOOBOT_HOME="${ZOOBOT_HOME:-$HOME/.zoobot}"
exec node "$INSTALL_HOME/packages/cli/bin/zoobot.mjs" "$@"
