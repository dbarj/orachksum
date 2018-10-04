#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Apr/2018 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error. Never remove it.
if [ $# -ne 4 -a $# -ne 5 ]
then
  echo "$0: Four or Five arguments are needed.. given: $#"
  exit 1
fi

v_chksdir="$1"
v_file1="$2"  # DB Out file - 4COMP HASH
v_file2="$3"  # Orig Hash - 4COMP HASH
v_file3="$4"  # Output File
v_file4="$5"  # DB Out file - FULL HASH

v_file5="${v_file1}.5"   # DB Out file - 4COMP NOHASH
v_file6="${v_file1}.6"   # Orig Hash File - 4COMP NOHASH
v_file7="${v_file1}.7"   # DB Out file - FULL NOHASH
v_file8="${v_file1}.8"   # NOT FOUND - FULL NOHASH
v_file9="${v_file1}.9"   # NOT FOUND or NO MATCH - FULL HASH
v_file10="${v_file1}.10" # NOT FOUND or NO MATCH - FULL NOHASH
v_file11="${v_file1}.11" # NO MATCH  - FULL NOHASH

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
else
  AWKCMD=awk
  AWKCMD_CSV="${AWKCMD} ${AWKCMD_P}"
  GREPCMD=grep
  SEDCMD=sed
fi

abortscript ()
{
    echo "$1"
	exit 1
}

if [ ! -f "${v_file1}" ]
then
  abortscript "${v_file1} not found."
fi

if [ ! -f "${v_file2}" ]
then
  abortscript "${v_file2} not found."
fi

if [ $# -eq 5 -a "${v_file1}" != "${v_file4}" -a ! -f "${v_file4}" ]
then
  abortscript "${v_file4} not found."
fi

printf %s\\n "$-" | $GREPCMD -q -F 'x' && v_dbgflag='-x' || v_dbgflag='+x'

${AWKCMD_CSV} --source '{csv_print_skip_last_record($0, separator, enclosure)}' "${v_file1}" > "${v_file5}"
${AWKCMD_CSV} --source '{csv_print_skip_last_record($0, separator, enclosure)}' "${v_file2}" > "${v_file6}"

if [ $# -eq 5 -a "${v_file1}" != "${v_file4}" ]
then
  ${AWKCMD_CSV} --source '{csv_print_skip_last_record($0, separator, enclosure)}' "${v_file4}" > "${v_file7}"

  sh ${v_dbgflag} ${v_chksdir}/sh/csv_compare_files.sh "${v_file1}" "${v_file2}" "${v_file9}" "${v_file4}"
  sh ${v_dbgflag} ${v_chksdir}/sh/csv_compare_files.sh "${v_file5}" "${v_file6}" "${v_file8}" "${v_file7}"
else
  sh ${v_dbgflag} ${v_chksdir}/sh/csv_compare_files.sh "${v_file1}" "${v_file2}" "${v_file9}"
  sh ${v_dbgflag} ${v_chksdir}/sh/csv_compare_files.sh "${v_file5}" "${v_file6}" "${v_file8}"
fi

${AWKCMD_CSV} --source '{csv_print_skip_last_record($0, separator, enclosure)}' "${v_file9}" > "${v_file10}"

sh ${v_dbgflag} ${v_chksdir}/sh/csv_compare_files.sh "${v_file10}" "${v_file8}" "${v_file11}"

touch "${v_file3}"

${AWKCMD} '{print $0"'${v_separator}'NO MATCH"}' "${v_file11}" > "${v_file11}.tmp"
mv "${v_file11}.tmp" "${v_file11}"

${AWKCMD} '{print $0"'${v_separator}'NOT FOUND"}' "${v_file8}" > "${v_file8}.tmp"
mv "${v_file8}.tmp" "${v_file8}"

cat "${v_file8}" > "${v_file3}"
cat "${v_file11}" >> "${v_file3}"

sort "${v_file3}" > "${v_file3}.tmp"
mv "${v_file3}.tmp" "${v_file3}"

rm -f "${v_file5}" "${v_file6}" "${v_file7}" "${v_file8}" "${v_file9}" "${v_file10}" "${v_file11}"

exit 0
###