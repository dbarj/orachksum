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
v_source="$2"
v_outfile="$3"
v_col_change="$4"
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

if [ "${v_source}" = "${v_outfile}" ]
then
  abortscript "Source and target files are the same. Skipping script."
fi

if [ $# -eq 3 ]
then
  cp "${v_source}" "${v_outfile}"
  echo "No compare columns for remove. Nothing to do."
  exit 0
fi

# Other scripts depends on this file created
rm -f "${v_outfile}"
touch "${v_outfile}"

if [ ! -s "${v_source}" ]
then
  abortscript "${v_source} is zero sized."
fi

# Number of fields
v_tot_fld=$(echo "${v_col_change}" | ${AWKCMD} -F';' '{print NF}')

# Replace in ${v_col_change} provided string (param1) all numbers greater than param2 to curvalue-1.
remake_colchange ()
{
  v_in_str="$1"
  v_in_number=$2
  v_out_str=""
  v_fld_rep=1
  while [ $v_fld_rep -le $v_tot_fld ]
  do
    read v_col_1 v_col_2 <<< $(echo "${v_in_str}" | ${AWKCMD} -F';' '{print $'${v_fld_rep}'}' | ${AWKCMD} -F',' '{print $1, $2}')
    [ ${v_col_1} -gt ${v_in_number} ] && v_col_1=$((v_col_1-1))
    [ ${v_col_2} -gt ${v_in_number} ] && v_col_2=$((v_col_2-1))
    v_out_str="${v_out_str}${v_col_1},${v_col_2};"
    v_fld_rep=$((v_fld_rep+1))
  done
  v_out_str=$(echo "${v_out_str}" | sed 's/.$//')
  echo "$v_out_str"
}

check_colchange ()
{
  v_fld_rep=1
  while [ $v_fld_rep -le $v_tot_fld ]
  do
    read v_col_1 v_col_2 <<< $(echo "${v_col_change}" | ${AWKCMD} -F';' '{print $'${v_fld_rep}'}' | ${AWKCMD} -F',' '{print $1, $2}')
    [ "${v_col_1}" -eq "${v_col_1}" ] 2>/dev/null || abortscript "v_col_change error. Found ${v_col_1}"
    [ "${v_col_2}" -eq "${v_col_2}" ] 2>/dev/null || abortscript "v_col_change error. Found ${v_col_2}"
    v_fld_rep=$((v_fld_rep+1))
  done
}

check_colchange

# Loop in fields to replace.
v_infile="${v_source}"
v_fld=1

while [ $v_fld -le $v_tot_fld ]
do
  read v_col_rep v_col_comp <<< $(echo "${v_col_change}" | ${AWKCMD} -F';' '{print $'${v_fld}'}' | ${AWKCMD} -F',' '{print $1, $2}')
  v_source_fields=$(head -n 1 "${v_infile}" | ${AWKCMD_CSV} --source '{a=csv_parse_record($0, separator, enclosure, csv); print a}')
  if [ ${v_source_fields} -lt ${v_col_rep} -o ${v_source_fields} -lt ${v_col_comp} ]
  then
    rm -f "${v_outfile}"
    [ "${v_infile}" != "${v_source}" -a -f "${v_infile}" ] && rm -f "${v_infile}"
    abortscript "v_source_fields ${v_source_fields} is lower then v_col_rep ${v_col_rep} or v_col_comp ${v_col_comp}"
  fi
  
  ${AWKCMD_CSV} --source '{csv_print_skip_field_record($0, separator, enclosure, '${v_col_comp}')}' "${v_infile}" > "${v_outfile}"
  
  if [ $v_tot_fld -gt 1 ]
  then
    v_infile="${v_outfile}.in"
    cp "${v_outfile}" "${v_infile}"
    # Replace in ${v_col_change} all numbers greater than ${v_col_comp} to curvalue-1.
    v_col_change=$(remake_colchange "${v_col_change}" "${v_col_comp}")
  fi
  v_fld=$((v_fld+1))
done

[ "${v_infile}" != "${v_source}" -a -f "${v_infile}" ] && rm -f "${v_infile}"
#####