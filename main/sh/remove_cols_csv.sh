#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Created      on: August/2017 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e
if [ $# -ne 4 -a $# -ne 3 ]
then
  echo "$0: Four arguments are needed.. given: $#"
  exit 1
fi

abortscript ()
{
  echo "$1"
  exit 1
}

v_chksdir="$1"
v_infile="$2"
v_outfile="$3"
v_col_remove="$4"
###

v_separator=','
v_enclosure='"'
AWKCMD_P="-f ${v_chksdir}/sh/csv-parser.awk -v separator=${v_separator} -v enclosure=${v_enclosure}"

SOTYPE=$(uname -s)
if [ "${SOTYPE}" = "SunOS" ]
then
  AWKCMD=gawk
  AWKCMD_CSV="${AWKCMD} ${AWKCMD_P}"
else
  AWKCMD=awk
  AWKCMD_CSV="${AWKCMD} ${AWKCMD_P}"
fi

if [ $# -eq 3 ]
then
  echo "No column for remove. Nothing to do."
  if [ "${v_source}" != "${v_outfile}" ]
  then
    cp "${v_source}" "${v_outfile}"
  fi
  exit 0
fi

# Other scripts depends on this file created
touch "${v_outfile}"

if [ ! -s "${v_infile}" ]
then
  abortscript "${v_infile} is zero sized."
fi

# "${v_outfile}.2" is used in case input and output are the same.

${AWKCMD_CSV} --source '{csv_print_skip_field_record($0, separator, enclosure, '${v_col_remove}')}' "${v_infile}" > "${v_outfile}.2"
mv "${v_outfile}.2" "${v_outfile}"

#####