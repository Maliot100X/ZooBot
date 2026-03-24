#!/usr/bin/env bash
# ZooBot CLI Wrapper - fully self-locating, works from any directory
# and respects actual install location (not caller's HOME)

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [ "${SOURCE#/}" = "$SOURCE" ] && SOURCE="$DIR/$SOURCE"
done
DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
INSTALL_HOME="$(cd "$DIR/.." && pwd)"

# Use ZOOBOT_HOME from env if explicitly set, otherwise use the actual install home
export ZOOBOT_HOME="${ZOOBOT_HOME:-$INSTALL_HOME}"

exec node "$INSTALL_HOME/packages/cli/bin/zoobot.mjs" "$@"
