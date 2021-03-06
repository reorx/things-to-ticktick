#!/bin/bash

set -eu
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


main() {
    require_sqlite3
    require_db

    case "${1-}" in
        "all")
            run_meta
            run_tasks
            ;;
        "tasks")
            run_tasks
            ;;
        "meta")
            run_meta
            ;;
        "stat")
            run_stat
            ;;
        "-h")
            echo_usage
            ;;
        *)
            echo_usage
            exit 1
            ;;
    esac
}


echo_usage() {
    cat <<EOF
Export tasks from Things.app to Dida365 backup format.

Usage: things_to_dida.sh COMMAND

COMMAND:
  all       export complete data to stdout
  tasks     export tasks CSV to stdout, part of the 'all' result
  meta      export metadata to stdout, part of the 'all' result
  stat      show statistic of tasks
EOF
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

run_tasks() {
    echo "$CSV_HEADER"
    sqlite3 -csv -separator "," "$THINGSDB" "$(echo_tasks_query)"
}


echo_tasks_query() {
    cat << EOF
SELECT
  "",
  iif(PROJECT_ITEM.project IS NULL, coalesce(PROJECT.title, AREA.title, "Inbox"), T.title),
  iif(length(T.title), T.title, "no title"),
  GROUP_CONCAT(TAG.title),
  iif(
    CL.task IS NULL,
    REPLACE(T.notes, CHAR(10), CHAR(13)),
    iif(T.notes = "", GROUP_CONCAT(CL.dida_title, ''), REPLACE(T.notes, CHAR(10), CHAR(13)) || '' || GROUP_CONCAT(CL.dida_title, ''))),
  iif(CL.task IS NULL, "N", "Y"),
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
LEFT OUTER JOIN $TASKTABLE PROJECT_ITEM ON T.uuid = PROJECT_ITEM.project
LEFT OUTER JOIN $AREATABLE AREA ON T.area = AREA.uuid
LEFT OUTER JOIN $TASKTABLE HEADING ON T.actionGroup = HEADING.uuid
LEFT OUTER JOIN $TASKTAGTABLE TAGS ON T.uuid = TAGS.tasks
LEFT OUTER JOIN $TAGTABLE TAG ON TAGS.tags = TAG.uuid
LEFT JOIN (
  SELECT iif($ISCLCOMPLETED, '???', '???') || title AS dida_title, task FROM $CLTABLE WHERE length(title) > 0
) CL ON CL.task = T.uuid
WHERE T.$ISNOTTRASHED AND (T.$ISOPEN OR T.$ISCOMPLETED)
GROUP BY T.uuid
ORDER BY T.creationDate DESC
EOF
}

run_meta() {
    cat << EOF
"Date: $(date +"%Y-%m-%d")+0000"
"Version: 7.0"
"Status: 
0 Normal
1 Completed
2 Archived"
EOF
}

run_stat() {
    local open_c=$(sqlite3 -csv "$THINGSDB" "$(echo_open_count_query)")
    local completed_c=$(sqlite3 -csv "$THINGSDB" "$(echo_completed_count_query)")
    echo "Tasks count:"
    echo "- open: $open_c"
    echo "- completed: $completed_c"
}

echo_open_count_query() {
    cat << EOF
SELECT count() FROM $TASKTABLE T
WHERE T.$ISNOTTRASHED AND T.$ISOPEN
EOF
}

echo_completed_count_query() {
    cat << EOF
SELECT count() FROM $TASKTABLE T
WHERE T.$ISNOTTRASHED AND T.$ISCOMPLETED
EOF
}

main "${@}"
