#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error
if [ $# -ne 4 ]
then
  echo "$0: Four arguments are needed.. given: $#"
  exit 1
fi
# set -x

abortscript ()
{
    echo "$1"
	exit 1
}

SOTYPE=$(uname -s)
if [ "${SOTYPE}" = "SunOS" ]
then
  GREPCMD=/usr/xpg4/bin/grep
else
  GREPCMD=grep
fi

v_dif_file="$1"
v_dbo_file="$2"
v_fieldsep="$3"
v_outputsql="$4"

echo "DEF orachk_tdf = ''"  > "${v_outputsql}"
echo "DEF orachk_mch = ''" >> "${v_outputsql}"
echo "DEF orachk_nmc = ''" >> "${v_outputsql}"
echo "DEF orachk_nfd = ''" >> "${v_outputsql}"

test -f "${v_dif_file}" || abortscript "${v_dif_file} does not exist."
test -f "${v_dbo_file}" || abortscript "${v_dbo_file} does not exist."

v_totdifs=$(cat "${v_dif_file}" | wc -l)
v_totdifs=$((v_totdifs-1)) #Remove Header

v_nomatch=$(${GREPCMD} -e "${v_fieldsep}NO MATCH$" "${v_dif_file}" | wc -l)
v_notfound=$(${GREPCMD} -e "${v_fieldsep}NOT FOUND$" "${v_dif_file}" | wc -l)

v_total=$(cat "${v_dbo_file}" | wc -l)
# v_match=$((v_total-v_notfound-v_nomatch)) # 
v_match=$((v_total-v_totdifs))

echo "DEF orachk_tdf = '${v_totdifs}'"   > "${v_outputsql}"
echo "DEF orachk_mch = '${v_match}'"    >> "${v_outputsql}"
echo "DEF orachk_nmc = '${v_nomatch}'"  >> "${v_outputsql}"
echo "DEF orachk_nfd = '${v_notfound}'" >> "${v_outputsql}"

exit 0
####