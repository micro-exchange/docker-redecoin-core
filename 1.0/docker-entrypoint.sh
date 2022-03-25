#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
  echo "$0: assuming arguments for redecoind"

  set -- redecoind "$@"
fi

if [ $(echo "$1" | cut -c1) = "-" ] || [ "$1" = "redecoind" ]; then
  mkdir -p "$REDECOIN_DATA"
  chmod 700 "$REDECOIN_DATA"
  chown -R redecoin "$REDECOIN_DATA"

  echo "$0: setting data directory to $REDECOIN_DATA"

  set -- "$@" -datadir="$REDECOIN_DATA"
fi

if [ "$1" = "redecoind" ] || [ "$1" = "redecoin-cli" ]; then
  echo
  exec su-exec redecoin "$@"
fi

echo
exec "$@"