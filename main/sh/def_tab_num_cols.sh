#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error
if [ $# -ne 3 -a $# -ne 4 ]
then
  echo "$0: Three or Four arguments are needed.. given: $#"
  exit 1
fi

abortscript ()
{
    echo "$1"
	exit 1
}

v_chksdir="$1"
v_file_pref="$2"
v_outputsql="$3"
v_col_change="$4"

AWKCMD_P="-f ${v_chksdir}/sh/csv-parser.awk -v separator=, -v enclosure=\""

SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" ]
then
  AWKCMD=gawk
  AWKCMD_CSV="${AWKCMD} ${AWKCMD_P}"
  GREPCMD=/usr/xpg4/bin/grep
  TRCMD=/usr/xpg4/bin/tr
else
  AWKCMD=awk
  AWKCMD_CSV="${AWKCMD} ${AWKCMD_P}"
  GREPCMD=grep
  TRCMD=tr
fi

v_type=$(echo "${v_file_pref}" | ${TRCMD} 'a-z' 'A-Z')
v_header=$(${GREPCMD} -e "^${v_type}:" "${v_chksdir}/sh/headers.txt" | ${AWKCMD} -F':' '{print $2}')
if [ "${v_header}" = "" ]
then
  v_num_cols_report=0
  v_num_cols_csv=0
  v_common_col_pos=0
  v_con_id_col_pos=0
else
  v_num_cols_report=$(echo "$v_header" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print a}')
  v_common_col_pos=$(echo "$v_header" | ${AWKCMD_CSV} --source '{a=csv_print_string_position($0, separator, enclosure, "COMMON"); print a}')
  v_con_id_col_pos=$(echo "$v_header" | ${AWKCMD_CSV} --source '{a=csv_print_string_position($0, separator, enclosure, "CON_ID"); print a}')
  v_num_cols_csv=${v_num_cols_report}
  if [ -n "${v_col_change}" ]
  then
    # Count how many columns are being replaced. If v_col_change is "N,M" it will be 1. If v_col_change is "N,M;O,P" it will be 2.
    v_replace_cols=$(echo "${v_col_change}" | ${AWKCMD} -F";" '{print NF}')
    v_num_cols_csv=$((v_num_cols_report+v_replace_cols))
    v_con_id_col_pos=$((v_con_id_col_pos+v_replace_cols))
  fi
  # When Header has "RESULT", it already counts +1, so no 7th parameter is needed. Only applied for hash checks.
fi

## Note:
## v_con_id_col_pos will be used before col_change happens. (Expand phase) CON_ID must be placed after them.
## v_common_col_pos will be used after col_change happens. (Compare phase) That's why we don't count the number of replaced cols on it.

echo "DEF orachk_tab_numcols_csv = '${v_num_cols_csv}'"     > "${v_outputsql}" # Number of columns of original CSV.
echo "DEF orachk_tab_numcols_rep = '${v_num_cols_report}'" >> "${v_outputsql}" # Number of columns excluding compare columns (that will be on report).
echo "DEF orachk_tab_common_col  = '${v_common_col_pos}'"  >> "${v_outputsql}" # Position of COMMON column (excluding compare columns).
echo "DEF orachk_tab_con_id_col  = '${v_con_id_col_pos}'"  >> "${v_outputsql}" # Position of CON_ID column (including compare columns).

exit 0
####