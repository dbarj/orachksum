#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Created      on: Apr/2018 by Rodrigo Jorge
# ----------------------------------------------------------------------------
set -e # Exit if error
if [ $# -ne 5 -a $# -ne 6 ]
then
  echo "$0: Five or Six arguments are needed.. given: $#"
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
v_conid_col="$4"
v_incl_root="$5"
v_list_pdbs="$6"

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

exit_not_number() {
  re='^[0-9]+$'
  if ! [[ $1 =~ $re ]] ; then
     abortscript "con_id is not a number. Found: $1"
  fi
}

rm -f ${v_outfile}
touch ${v_outfile}

if [ ! -s "${v_infile}" ]
then
  exit 0
fi

#####################################

dist_con_ids_list=$(echo "${v_list_pdbs}" | tr "," "\n")
dist_con_ids=(${dist_con_ids_list})
for t_con_id in "${dist_con_ids[@]}"
do
  exit_not_number ${t_con_id}
done

if [ -n "${v_list_pdbs}" ] # Multitenant or Non-Multitenant
then
 ####
 ${AWKCMD_CSV} --source '{csv_expand_multitenant($0, separator, enclosure, "'${v_list_pdbs}'", '${v_conid_col}', '${v_incl_root}')}' "${v_infile}" >  ${v_outfile}
 ####
elif [ -z "${v_list_pdbs}" ] # Null - 11g
then
 ####
 cp "${v_infile}" "${v_outfile}"
 ####
fi

exit 0
####