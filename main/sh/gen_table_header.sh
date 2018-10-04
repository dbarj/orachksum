#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error
if [ $# -ne 3 ]
then
  echo "$0: Three arguments are needed.. given: $#"
  exit 1
fi
# set -x

abortscript ()
{
    echo "$1"
	exit 1
}

v_chksdir="$1"
v_file_pref="$2"
v_out_file="$3"

AWKCMD_P="-f ${v_chksdir}/sh/csv-parser.awk -v separator=, -v enclosure=\""

SOTYPE=$(uname -s)
if [ "$SOTYPE" = "SunOS" ]
then
  AWKCMD=/usr/xpg4/bin/awk
  GREPCMD=/usr/xpg4/bin/grep
  TRCMD=/usr/xpg4/bin/tr
else
  AWKCMD=awk
  GREPCMD=grep
  TRCMD=tr
fi

v_type=$(echo "${v_file_pref}" | ${TRCMD} 'a-z' 'A-Z')
v_header=$(${GREPCMD} -e "^${v_type}:" "${v_chksdir}/sh/headers.txt" | ${AWKCMD} -F':' '{print $2}')
if [ "${v_header}" = "" ]
then
  abortscript "${v_type} not found."
else
  echo "VAR orachk_cols VARCHAR2(4000)"    >  "${v_out_file}"
  echo "BEGIN"                             >> "${v_out_file}"
  echo " :orachk_cols := '${v_header}';"   >> "${v_out_file}"
  echo "END;"                              >> "${v_out_file}"
  echo "/"                                 >> "${v_out_file}"
fi

exit 0
####