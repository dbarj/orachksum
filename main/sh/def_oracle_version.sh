#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error
if [ $# -ne 2 ]
then
  echo "$0: Two arguments are needed.. given: $#"
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

v_version_file="$1"
v_outputsql="$2"

echo "DEF orachk_ver_oraversion = ''"  > "${v_outputsql}"
echo "DEF orachk_ver_ps_type    = ''" >> "${v_outputsql}"
echo "DEF orachk_ver_ps_value   = ''" >> "${v_outputsql}"
echo "DEF orachk_ver_ojvmpsu    = ''" >> "${v_outputsql}"
echo "DEF orachk_ver_pdbs       = ''" >> "${v_outputsql}"

[ ! -f "${v_version_file}" ] && abortscript "${v_version_file} not found."

v_unsupported=$(cat "${v_version_file}" | grep "ORA-20000" | wc -l)
if [ ${v_unsupported} -eq 1 ]
then
  abortscript "Unsupported version."
else
  v_output=$(cat "${v_version_file}")
  v_output_array=(${v_output})
  v_oraversion="${v_output_array[0]}"
  v_ps_type="${v_output_array[1]}"
  v_ps_value="${v_output_array[2]}"
  v_ojvmpsu="${v_output_array[3]}"
  v_pdbs="${v_output_array[4]}"
fi


echo "DEF orachk_ver_oraversion = '${v_oraversion}'"  > "${v_outputsql}"
echo "DEF orachk_ver_ps_type    = '${v_ps_type}'"    >> "${v_outputsql}"
echo "DEF orachk_ver_ps_value   = '${v_ps_value}'"   >> "${v_outputsql}"
echo "DEF orachk_ver_ojvmpsu    = '${v_ojvmpsu}'"    >> "${v_outputsql}"
echo "DEF orachk_ver_pdbs       = '${v_pdbs}'"       >> "${v_outputsql}"

exit 0
####