#!/bin/sh

# ================== CONFIG ==================
SMTP_SERVER="10.14.20.164"
SMTP_PORT=25
EMAIL_FROM="backup-korporat@iconpln.co.id"
EMAIL_TO="ando.wibawa@iconpln.co.id"
SUBJECT="[Backup Report] Weekly backup report for pgBackrest"
TIMEZONE="Asia/Jakarta"

# ============== FUNCTIONS ===================
# Convert bytes to GiB with 2 decimal places
bytes_to_gib() {
    awk "BEGIN {printf \"%.2f GiB\", $1 / (1024 * 1024 * 1024)}"
}

epoch_to_date() {
    TZ="$TIMEZONE" date -d "@$1" +"%Y-%m-%d %H:%M:%S"
}

send_html_email() {
    subject="$1"
    html_body="$2"

    sendemail -f "$EMAIL_FROM" \
              -t "$EMAIL_TO" \
              -u "$subject" \
              -m "$html_body" \
              -s "$SMTP_SERVER:$SMTP_PORT" \
              -o message-content-type=html \
              -o message-charset=utf-8 \
              -o tls=no
}

# ========== CHECK DEPENDENCIES =============
command -v jq >/dev/null || { echo "❌ jq not found"; exit 1; }
command -v sendemail >/dev/null || { echo "❌ sendemail not found"; exit 1; }

# ========== BUILD HTML TABLE HEADER =========
html_table="
<h2>📦 Weekly Backup Report</h2>
<p>Dear Team,<br>
Here's the weekly backup report for pgBackRest.</p>

<table border='1' cellpadding='6' cellspacing='0' style='border-collapse:collapse;'>
  <thead>
    <tr>
      <th>Database</th>
      <th>Type</th>
      <th>Label</th>
      <th>Status</th>
      <th>Start Time</th>
      <th>End Time</th>
      <th>Size</th>
    </tr>
  </thead>
  <tbody>
"

# ========== LOOP THROUGH STANZAS ============
for stanza_json in $(pgbackrest info --output=json | jq -c '.[]'); do
    STANZA_NAME=$(echo "$stanza_json" | jq -r '.name')
    DB_NAME=$(echo "$STANZA_NAME" | tr '[:lower:]' '[:upper:]')

    full_backup=$(echo "$stanza_json" | jq '[.backup[] | select(.type == "full")][-1]')
    incr_backup=$(echo "$stanza_json" | jq '[.backup[] | select(.type == "incr")][-1]')

    for backup in "$full_backup" "$incr_backup"; do
        label=$(echo "$backup" | jq -r '.label')
        type=$(echo "$backup" | jq -r '.type')
        error=$(echo "$backup" | jq -r '.error')
        size=$(echo "$backup" | jq -r '.info.size // 0')
        start_epoch=$(echo "$backup" | jq -r '.timestamp.start // empty')
        stop_epoch=$(echo "$backup" | jq -r '.timestamp.stop // empty')

        # Skip if backup is null or empty
        if [ -z "$label" ] || [ "$label" = "null" ]; then
            continue
        fi

        start_fmt=$(epoch_to_date "$start_epoch")
        stop_fmt=$(epoch_to_date "$stop_epoch")
        size_hr=$(bytes_to_gib "$size")

        if [ "$error" = "true" ]; then
            status="❌ <span style='color:red;'>FAILED</span>"
        else
            status="✅ <span style='color:green;'>SUCCESS</span>"
        fi

        html_table="$html_table
        <tr>
          <td><b>$DB_NAME</b></td>
          <td>$type</td>
          <td>$label</td>
          <td>$status</td>
          <td>$start_fmt</td>
          <td>$stop_fmt</td>
          <td>$size_hr</td>
        </tr>"
    done
done

# ========== CLOSE TABLE =====================
html_table="$html_table
  </tbody>
</table>
<p style='font-size:12px;color:gray;'>Generated at: $(date '+%Y-%m-%d %H:%M:%S')</p>
"

# ============== SEND EMAIL ==================
html_body="<html><body style='font-family:sans-serif;'>$html_table</body></html>"
send_html_email "$SUBJECT" "$html_body"