#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
if [ $# -ne 4 -a $# -ne 5 ]
then
  echo "$0: Four or Five arguments are needed.. given: $#"
  exit 1
fi

v_chksdir="$1"
v_dbcsv="$2"
v_origcsv="$3"
v_output="$4"
v_col_change="$5"

v_separator=','
v_enclosure='"'

AWKCMD_P="-f ${v_chksdir}/sh/csv-parser.awk -v separator=${v_separator} -v enclosure=${v_enclosure}"

SOTYPE=$(uname -s)
if [ "${SOTYPE}" = "SunOS" ]
then
  AWKCMD=gawk
  AWKCMD_CSV="${AWKCMD} ${AWKCMD_P}"
  GREPCMD=/usr/xpg4/bin/grep
  SEDCMD=/usr/xpg4/bin/sed
  ECHOCMD=/usr/gnu/bin/echo
else
  AWKCMD=awk
  AWKCMD_CSV="${AWKCMD} ${AWKCMD_P}"
  GREPCMD=grep
  SEDCMD=sed
  ECHOCMD=echo
fi

abortscript ()
{
    echo "$1"
	exit 1
}

exit_not_number() {
  re='^[0-9]+$'
  if ! [[ $1 =~ $re ]] ; then
     abortscript "con_id is not a number. Found: $1"
  fi
}

progressbar ()
{
 str="#"
 maxhashes=24
 perc=$1
 numhashes=$(( ( $perc * $maxhashes ) / 100 ))
 numspaces=$(( $maxhashes - $numhashes ))
 phash=$(printf "%-${numhashes}s" "$str")
 [ $numhashes -eq 0 ] && phash="" || true
 pspace=$(printf "%-${numspaces}s" " ")
 [ $numspaces -eq 0 ] && pspace="" || true
 ${ECHOCMD} -ne "${phash// /$str}${pspace}   (${perc}%)\r" > /dev/tty
 [ $perc -eq 100 ] && ${ECHOCMD} -ne "${phash//$str/ }         \r" > /dev/tty || true
}

printpercentage ()
{
 perc=$(( ( $curline * 100 ) / $totline ))
 [ $perc -ne $perc_b4 ] && progressbar $perc || true
 perc_b4=$perc
 curline=$(( $curline + 1 ))
}

if [ -n "${v_col_change}" ]
then
  read v_col_rep v_col_comp <<< $(echo ${v_col_change} | ${AWKCMD} -F',' '{print $1, $2}')
  [ "${v_col_rep}" -eq "${v_col_rep}" ]   2>/dev/null || abortscript "v_col_rep error. Found ${v_col_rep}"
  [ "${v_col_comp}" -eq "${v_col_comp}" ] 2>/dev/null || abortscript "v_col_comp error. Found ${v_col_rep}"
fi

### Escape REGEX patterns of param
ere_quote() {
  ${SEDCMD} 's/[]\.|$(){}?+*^]/\\&/g' <<< "$*"
}

if [ ! -f "${v_dbcsv}" ]
then
  exit 1
fi

if [ ! -f "${v_origcsv}" ]
then
  v_origcsv=/dev/null
fi

rm -f "${v_output}"

v_last_col=$(head -n 1 "${v_dbcsv}" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print a}')

totline=$(cat "${v_dbcsv}" | wc -l)
curline=1
perc_b4=-1

if [ -z "${v_col_change}" ]
then
  v_dbcsv_base0="${v_dbcsv}.base0"
  ${AWKCMD_CSV} --source '{csv_print_until_field_record($0, separator, enclosure, '$((v_last_col-2))')}' "${v_dbcsv}" > "${v_dbcsv_base0}"
else
  v_dbcsv_base0="${v_dbcsv}.base0"
  ${AWKCMD_CSV} --source '{csv_print_exchange_field_records_skip_2last($0, separator, enclosure, '${v_col_rep}', '${v_col_comp}')}' "${v_dbcsv}" > "${v_dbcsv_base0}"
  v_dbcsv_out0="${v_dbcsv}.out0"
  ${AWKCMD_CSV} --source '{csv_print_skip_field_record_and_2last($0, separator, enclosure, '${v_col_comp}')}' "${v_dbcsv}" > "${v_dbcsv_out0}"
fi

while read -r c_line || [ -n "${c_line}" ]
do
 # Base0 is the line to be compared, while Out0 is the line to be printed. Both don't have con_id.
 if [ -z "${v_col_change}" ]
 then
  line_base0=$(${AWKCMD} 'NR=='${curline} "${v_dbcsv_base0}")
  line_out0="$line_base0"
 else
  line_base0=$(${AWKCMD} 'NR=='${curline} "${v_dbcsv_base0}")
  line_out0=$(${AWKCMD} 'NR=='${curline} "${v_dbcsv_out0}")
 fi
 read c_con_id <<< $(echo "$c_line" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv['$((v_last_col-2))']}')
 read c_hash   <<< $(echo "$c_line" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv['$((v_last_col-1))']}')
 [ -n "${c_con_id}" ] && exit_not_number "${c_con_id}"
 c_conid_comp=${c_con_id}
 [ -n "${c_con_id}" ] && { test ${c_con_id} -gt 2 && c_conid_comp=2; }
 line_out0="${line_out0}${v_separator}${c_con_id}${v_separator}"
 line_comp="${line_base0}${v_separator}${c_conid_comp}${v_separator}"
 ${GREPCMD} -q -e "^$(ere_quote ${line_comp})" "${v_origcsv}"; ret=$?
 if [ ${ret} -ne 0 ]
 then
  echo "${line_out0}NOT FOUND" >> "${v_output}"
 else
  line_hash="${line_comp}${c_hash}"
  ${GREPCMD} -q -Fx "${line_hash}" "${v_origcsv}"; ret=$?
  if [ ${ret} -ne 0 ]
  then
   echo "${line_out0}NO MATCH" >> "${v_output}"
  fi
 fi
 ## Print Percentage
 printpercentage
done < "${v_dbcsv}"

if [ -z "${v_col_change}" ]
then
  rm -f "${v_dbcsv_base0}"
else
  rm -f "${v_dbcsv_base0}" "${v_dbcsv_out0}"
fi
####
