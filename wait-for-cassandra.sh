#!/bin/sh
set -e
cmd="$@"

until cqlsh -e 'desc keyspaces'; do
  >&2 echo "Cassandra is unavailable - sleeping"
  sleep 1
done

>&2 echo "Cassandra is up - migrating schema"
exec $cmd
