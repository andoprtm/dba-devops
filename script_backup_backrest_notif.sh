#!/bin/bash

STANZA="alihdaya_db"
TYPE="full"
TMP_OUTPUT="/var/lib/pgbackrest/log_backup/alihdaya_db/log_full_backup_alihdaya_db_$(date +\%Y\%m\%d_%I\%M\%p).log"
TIMESTAMP=$(date)

# Run pgbackrest and capture both stdout & stderr
pgbackrest --stanza=$STANZA --type=$TYPE backup > "$TMP_OUTPUT" 2>&1
EXIT_CODE=$?

# If failed
if [ $EXIT_CODE -ne 0 ]; then
    EXCEPTION=$(grep -E "exception \[[0-9]+\]" "$TMP_OUTPUT" | tail -5)
    if [ -z "$EXCEPTION" ]; then
        EXCEPTION="Backup failed with unknown error (exit code $EXIT_CODE)"
    fi

    /var/lib/pgbackrest/script/notify_failure.sh "$STANZA" "full" "$TIMESTAMP" "$EXCEPTION"
    exit 1
fi