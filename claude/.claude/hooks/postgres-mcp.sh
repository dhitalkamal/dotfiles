#!/bin/bash
# walks up from CWD to find a .env with DATABASE_URL, then starts the postgres MCP server
# falls back to localhost/postgres if nothing is found

DIR=$(pwd)
DB_URL=""

while [ "$DIR" != "/" ] && [ -z "$DB_URL" ]; do
    if [ -f "$DIR/.env" ]; then
        DB_URL=$(grep -E '^DATABASE_URL=' "$DIR/.env" | head -1 | sed 's/^DATABASE_URL=//' | tr -d '"'"'"' ')
    fi
    DIR=$(dirname "$DIR")
done

exec yarn dlx @modelcontextprotocol/server-postgres "${DB_URL:-postgresql://localhost:5432/postgres}"
