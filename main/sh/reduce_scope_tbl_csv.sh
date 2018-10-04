#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Created      on: Dec/2016 by Rodrigo Jorge
# Last updated on: Nov/2017 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e
if [ $# -ne 8 ]
then
  echo "$0: Eight arguments are needed.. given: $#"
  exit 1
fi

abortscript ()
{
    echo "$1"
	exit 1
}

v_chksdir="$1"
v_oraversion="$2"
v_pstype="$3"
v_psvalue="$4"
v_ojvmpsu="$5"
v_source="$6"
v_outfile="$7"
###
v_last_col="$8"

AWKCMD_P="-f ${v_chksdir}/sh/csv-parser.awk -v separator=, -v enclosure=\""

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
  ECHOCMD="echo"
fi

### Escape REGEX patterns of param
ere_quote() {
    $SEDCMD 's/[]\.|$(){}?+*^]/\\&/g' <<< "$*"
}

v_source_fields=$(head -n 1 "$v_source" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print a}')

## If file has less columns than should, abort.
if [ $v_source_fields -lt $((v_last_col+4)) ]
then
  abortscript "File $v_source has less columns than should. Expected at least $((v_last_col+4)). Found $v_source_fields."
fi

v_patch_series="$v_pstype"
v_patch_version="$v_psvalue"

rm -f "${v_outfile}"
touch "${v_outfile}"

v_source_col_series=$((v_last_col+1))
v_source_col_oraversion=$((v_last_col+2))
v_source_col_psu_from=$((v_last_col+3))
v_source_col_psu_to=$((v_last_col+4))
v_source_col_flag=$((v_last_col+5))

v_awk_col_series=$((v_source_col_series-1))
v_awk_col_oraversion=$((v_source_col_oraversion-1))
v_awk_col_psu_from=$((v_source_col_psu_from-1))
v_awk_col_psu_to=$((v_source_col_psu_to-1))
v_awk_col_flag=$((v_source_col_flag-1))

addline ()
{
  echo "${c_line_print}" >> "${v_outfile}"
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

totline=$(cat "${v_source}" | wc -l)
curline=1
perc_b4=-1

while read -r c_line || [ -n "$c_line" ]
do
 c_line_print=$(echo "$c_line" | ${AWKCMD_CSV} --source '{csv_print_until_field_record($0, separator, enclosure, '$v_last_col')}')
 read c_series c_oraversion c_from c_to <<< $(echo "$c_line" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv['$v_awk_col_series'], csv['$v_awk_col_oraversion'], csv['$v_awk_col_psu_from'], csv['$v_awk_col_psu_to']}')

 if [ "${v_oraversion}" = "${c_oraversion}" -a "${c_series}" = "${v_patch_series}" -a ${v_patch_version} -ge ${c_from} -a ${v_patch_version} -le ${c_to} ]
 then
  addline
 elif [ "${v_oraversion}" = "${c_oraversion}" -a "${c_series}" = "BOTH" -a ${v_patch_version} -ge ${c_from} -a ${v_patch_version} -le ${c_to} ]
 then
  addline
 fi
 ## Print Percentage
 printpercentage
done < "${v_source}"

if [ ${v_ojvmpsu} -gt 0 ]
then
  ${GREPCMD} -F ",OJVM,"  "${v_source}"   > "${v_source}.2" || touch "${v_source}.2"
  ${GREPCMD} -F ",-1,-1," "${v_source}.2" > "${v_source}.3" || touch "${v_source}.3"
  ## Remove Privs
  while read -r c_line || [ -n "$c_line" ]
  do
    c_line_print=$(echo "$c_line" | ${AWKCMD_CSV} --source '{csv_print_until_field_record($0, separator, enclosure, '$v_last_col')}')
    read c_series c_oraversion c_from c_to <<< $(echo "$c_line" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv['$v_awk_col_series'], csv['$v_awk_col_oraversion'], csv['$v_awk_col_psu_from'], csv['$v_awk_col_psu_to']}')

    if [ "${v_oraversion}" = "${c_oraversion}" -a "${c_series}" = "OJVM" -a -1 -ge ${c_from} -a -1 -le ${c_to} ]
    then
     ${GREPCMD} -q -Fx "${c_line_print}" "${v_outfile}" && ret=$? || ret=$?
     if [ $ret -eq 0 ]
     then
        ${GREPCMD} -v -Fx "${c_line_print}" "${v_outfile}" > "${v_outfile}.2"
        mv "${v_outfile}.2" "${v_outfile}"
     fi
    fi
  done < "${v_source}.3"
  ## Add OJVM
  while read -r c_line || [ -n "$c_line" ]
  do
    c_line_print=$(echo "$c_line" | ${AWKCMD_CSV} --source '{csv_print_until_field_record($0, separator, enclosure, '$v_last_col')}')
    read c_series c_oraversion c_from c_to <<< $(echo "$c_line" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv['$v_awk_col_series'], csv['$v_awk_col_oraversion'], csv['$v_awk_col_psu_from'], csv['$v_awk_col_psu_to']}')
    c_flag=$(echo "$c_line" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print csv['$v_awk_col_flag']}')

    if [ "${v_oraversion}" = "${c_oraversion}" -a "${c_series}" = "OJVM" -a ${v_ojvmpsu} -ge ${c_from} -a ${v_ojvmpsu} -le ${c_to} ]
    then
      ${GREPCMD} -q -Fx "${c_line_print}" "${v_outfile}" && ret=$? || ret=$?
      if [ $ret -eq 0 ]
      then
         ${GREPCMD} -v -Fx "${c_line_print}" "${v_outfile}" > "${v_outfile}.2"
         mv "${v_outfile}.2" "${v_outfile}"
      fi
      [ -z "${c_flag}" ] && addline
    fi
  done < "${v_source}.2"
  rm -f "${v_source}.2"
  rm -f "${v_source}.3"
fi

sort "${v_outfile}" | uniq > "${v_outfile}.2"
mv "${v_outfile}.2" "${v_outfile}"
#####