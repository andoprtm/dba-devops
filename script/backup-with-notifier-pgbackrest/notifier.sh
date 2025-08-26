#!/bin/bash

# Email config
EMAIL_FROM="xx@example.com" 
EMAIL_TO="xx@example.com"
SUBJECT_PREFIX="xxxxxx"
SMTP_SERVER="xx.xx.xx.xx" #snmtp-server
SMTP_PORT=25

# Input args
STANZA="$1"
BACKUP_TYPE="$2"
TIMESTAMP="$3"
ERROR_MSG="$4"

# Email subject
SUBJECT="$SUBJECT_PREFIX FAILED [$STANZA - $BACKUP_TYPE]"

# Create HTML email body
EMAIL_BODY=$(cat <<EOF
<html>
  <body style="font-family:Arial, sans-serif;">
    <h2 style="color:#d9534f;">🚨 pgBackRest Backup FAILED</h2>
    <p><strong>Stanza:</strong> $STANZA</p>
    <p><strong>Backup Type:</strong> $BACKUP_TYPE</p>
    <p><strong>Timestamp:</strong> $TIMESTAMP</p>
    <p><strong>Error Log:</strong></p>
    <pre style="background:#f8f9fa;border:1px solid #ccc;padding:10px;">$ERROR_MSG</pre>
  </body>
</html>
EOF
)

# Send email using sendemail
sendemail -f "$EMAIL_FROM" \
          -t "$EMAIL_TO" \
          -u "$SUBJECT" \
          -m "$EMAIL_BODY" \
          -s "$SMTP_SERVER:$SMTP_PORT" \
          -o message-content-type=html \
          -o message-charset=utf-8 \
          -o tls=no
