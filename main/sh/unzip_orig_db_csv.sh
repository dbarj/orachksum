#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error
if [ $# -ne 5 ]
then
  echo "$0: Five arguments are needed.. given: $#"
  exit 1
fi

abortscript ()
{
    echo "$1"
	exit 1
}

v_chksdir="$1"
v_oraversion="$2"
v_file_pref="$3"
v_srczip_file_pref="$4"
v_outfile="$5"

v_outfile_path=$(dirname "${v_outfile}")

v_source="${v_chksdir}/csv/${v_srczip_file_pref}.csv.zip"
v_orig_csv=${v_file_pref}.${v_oraversion}.csv

[ ! -f "${v_source}" ] && { touch "${v_outfile}"; abortscript "${v_source} not found."; }
unzip -o "${v_source}" "${v_orig_csv}" -d "${v_outfile_path}" > /dev/null 2>&- || { touch "${v_outfile}"; abortscript "${v_source} does not have ${v_orig_csv}."; }
mv "${v_outfile_path}/${v_orig_csv}" "${v_outfile}"

exit 0
####