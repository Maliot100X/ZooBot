#!/usr/bin/env bash
ZOO_BOT_HOME="${ZOOBOT_HOME:-$HOME/.zoobot}"
exec node "$ZOO_BOT_HOME/packages/cli/bin/zoobot.mjs" "$@"
