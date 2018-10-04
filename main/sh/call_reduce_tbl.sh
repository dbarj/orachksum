#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error
if [ $# -ne 6 -a $# -ne 7 ]
then
  echo "$0: Six or Seven arguments are needed.. given: $#"
  exit 1
fi

abortscript ()
{
    echo "$1"
	exit 1
}

v_chksdir="$1"
v_version_file="$2"
v_red_src="$3"
v_report="$4"
v_file_pref="$5"
v_srczip_file_pref="$6"
v_col_change="$7"

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

[ ! -f "${v_version_file}" ] && abortscript "${v_version_file} not found."

v_unsupported=$(cat "${v_version_file}" | grep "ORA-20000" | wc -l)
if [ ${v_unsupported} -eq 1 ]
then
  abortscript "Unsupported version."
else
  v_output=$(cat "${v_version_file}")
  v_output_array=(${v_output})
  v_oraversion="${v_output_array[0]}"
  v_pstype="${v_output_array[1]}"
  v_psvalue="${v_output_array[2]}"
  v_ojvmpsu="${v_output_array[3]}"
  v_pdbs="${v_output_array[4]}"
fi

v_type=$(echo "${v_file_pref}" | ${TRCMD} 'a-z' 'A-Z')
v_header=$(${GREPCMD} -e "^${v_type}:" "${v_chksdir}/sh/headers.txt" | ${AWKCMD} -F':' '{print $2}')
if [ "${v_header}" = "" ]
then
  v_num_cols=0
else
  v_num_cols=$(echo "$v_header" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print a}')
  if [ -n "${v_col_change}" ]
  then
    # Count how many columns are being replaced. If v_col_change is "N,M" it will be 1. If v_col_change is "N,M;O,P" it will be 2.
    v_rep_cols=$(echo "${v_col_change}" | ${AWKCMD} -F";" '{print NF}')
    v_num_cols=$((v_num_cols+v_rep_cols))
  fi
  # When Header has "RESULT", it already counts +1, so no 7th parameter is needed. Only applied for hash checks.
fi

v_prev_red_zip="${v_chksdir}/csv/red_${v_oraversion}_${v_pstype}_${v_psvalue}_${v_ojvmpsu}.zip"

v_red_src_file=$(basename "${v_red_src}")
v_red_src_path=$(dirname "${v_red_src}")

skip_unzip=0
if [ -f "${v_prev_red_zip}" ]
then
  unzip -o "${v_prev_red_zip}" "${v_red_src_file}" -d "${v_red_src_path}" > /dev/null 2>&- || true
  [ -f "${v_red_src}" ] && skip_unzip=1
fi

if [ ${skip_unzip} -eq 0 ]
then
  v_source="${v_chksdir}/csv/${v_srczip_file_pref}.csv.zip"

  v_orig_csv=${v_file_pref}.${v_oraversion}.csv

  #unzipdir="${v_chksdir}/csv/temp"
  unzipdir="${v_red_src_path}"

  [ ! -f "${v_source}" ] && { touch ${v_red_src}; abortscript "${v_source} not found."; }
  #[ ! -d "${unzipdir}" ] && mkdir "${unzipdir}"
  unzip -o "${v_source}" "${v_orig_csv}" -d "${unzipdir}" > /dev/null 2>&- || { touch ${v_red_src}; abortscript "${v_source} does not have ${v_orig_csv}."; }

  printf %s\\n "$-" | $GREPCMD -q -F 'x' && v_dbgflag='-x' || v_dbgflag='+x'

  sh ${v_dbgflag} ${v_chksdir}/sh/reduce_scope_tbl_csv.sh ${v_chksdir} ${v_oraversion} ${v_pstype} ${v_psvalue} ${v_ojvmpsu} "${unzipdir}/${v_orig_csv}" "${v_red_src}" ${v_num_cols}

  rm -f "${unzipdir}/${v_orig_csv}"
  #rmdir "${unzipdir}"

  zip -jT "${v_prev_red_zip}" "${v_red_src}" > /dev/null 2>&-
fi

echo "Oracle Version = ${v_oraversion}"                 >> "${v_report}"
echo "Latest PS Type Applied = ${v_pstype}"             >> "${v_report}"
echo "Latest PS Value = ${v_psvalue}"                   >> "${v_report}"
echo "Latest OJVM PSU Applied = ${v_ojvmpsu}"           >> "${v_report}"
echo "PDBs: ${v_pdbs}"                                  >> "${v_report}"
echo "-------------"                                    >> "${v_report}"

exit 0
####