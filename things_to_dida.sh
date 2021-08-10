#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
[[ "${TRACE:-}" ]] && set -x


: ${THINGSDB:="$HOME/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/Things Database.thingsdatabase/main.sqlite"}

# Things database structure
readonly TASKTABLE="TMTask"
readonly AREATABLE="TMArea"
readonly TAGTABLE="TMTag"
readonly TASKTAGTABLE="TMTaskTag"
readonly CLTABLE="TMChecklistItem"
readonly ISNOTTRASHED="trashed = 0"
readonly ISTRASHED="trashed = 1"
readonly ISOPEN="status = 0"
readonly ISCOMPLETED="status = 3"
readonly ISCLCOMPLETED="status = 3"

CSV_HEADER='"Folder Name","List Name","Title","Tags","Content","Is Check list","Start Date","Due Date","Reminder","Repeat","Priority","Status","Created Time","Completed Time","Order","Timezone","Is All Day","Is Floating","Column Name","Column Order","View Mode","taskId","parentId"'


function main() {
    require_sqlite3
    require_db

    echo "$CSV_HEADER"
    sqlite3 -csv -separator "," "$THINGSDB" "$(echo_tasks_query)" | awk '{gsub("<[^>]*>", "")}1'
}

require_sqlite3() {
  command -v sqlite3 >/dev/null 2>&1 || {
    echo >&2 "ERROR: SQLite3 is required but could not be found."
    exit 1
  }
}

require_db() {
  test -r "$THINGSDB" -a -f "$THINGSDB" || {
    echo >&2 "ERROR: Things database not found at '$THINGSDB'."
    exit 2
  }
}


function echo_tasks_query() {
    cat << EOF
SELECT
  "",
  coalesce(PROJECT.title, AREA.title, "Inbox"),
  iif(length(T.title), T.title, "no title"),
  GROUP_CONCAT(TAG.title),
  iif(
    C1.task IS NULL,
    REPLACE(T.notes, CHAR(10), CHAR(13)),
    iif(T.notes = "", GROUP_CONCAT(C1.dida_title, ''), REPLACE(T.notes, CHAR(10), CHAR(13)) || '' || GROUP_CONCAT(C1.dida_title, ''))),
  iif(C1.task IS NULL, "N", "Y"),
  "",
  "",
  "",
  "",
  "0",
  iif(T.stopDate IS NULL, '0', '2'),
  strftime('%Y-%m-%dT%H:%M:%S+0000', T.creationDate,"unixepoch"),
  strftime('%Y-%m-%dT%H:%M:%S+0000', T.stopDate,"unixepoch"),
  row_number() OVER (ORDER BY T.creationDate DESC),
  "Asia/Shanghai",
  NULL,
  "false",
  NULL,
  NULL,
  "list",
  row_number() OVER (ORDER BY T.creationDate DESC),
  ""
FROM $TASKTABLE T
LEFT OUTER JOIN $TASKTABLE PROJECT ON T.project = PROJECT.uuid
LEFT OUTER JOIN $AREATABLE AREA ON T.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON T.actionGroup = HEADING.uuid
LEFT OUTER JOIN $TASKTAGTABLE TAGS ON T.uuid = TAGS.tasks
LEFT OUTER JOIN $TAGTABLE TAG ON TAGS.tags = TAG.uuid
LEFT JOIN (
  SELECT iif($ISCLCOMPLETED, '▪', '▫') || title AS dida_title, task FROM $CLTABLE WHERE length(title) > 0
) C1 ON C1.task = T.uuid
WHERE T.$ISNOTTRASHED AND (T.$ISOPEN OR T.$ISCOMPLETED)
GROUP BY T.uuid
ORDER BY T.creationDate DESC
EOF
}

main
