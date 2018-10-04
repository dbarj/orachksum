#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error. Never remove it.
if [ $# -ne 3 ]
then
  echo "$0: Three arguments are needed.. given: $#"
  exit 1
fi
#set -x

abortscript ()
{
    echo "$1"
	exit 1
}

v_chksdir="$1"
v_csvfile="$2"
v_type="$3"

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

if [ ! -f "${v_csvfile}" ]
then
  abortscript "${v_csvfile} not found."
fi

v_type=$(echo "$v_type" | ${TRCMD} 'a-z' 'A-Z')
v_header=$(${GREPCMD} -e "^${v_type}:" "${v_chksdir}/sh/headers.txt" | ${AWKCMD} -F':' '{print $2}')

if [ "${v_header}" = "" ]
then
  v_header="HEADER ERROR"
fi

if [ -f "${v_csvfile}" ]
then
  (echo ${v_header}; cat "${v_csvfile}") > "${v_csvfile}.2"
  mv "${v_csvfile}.2" "${v_csvfile}"
else
  echo ${v_header} > "${v_csvfile}"
fi

exit 0
####