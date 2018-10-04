#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Dec/2016 by Rodrigo Jorge
# ----------------------------------------------------------------------------
if [ $# -ne 2 ]
then
  echo "$0: Two arguments are needed.. given: $#"
  exit 1
fi

# Not working in Solaris. Must change "echo -e" to "echo".

v_varname=$1
v_sourcecsv=$2

echo "var ${v_varname} = new google.visualization.DataTable();"
echo "${v_varname}.addColumn('string', 'Owner');"
echo "${v_varname}.addColumn('string', 'Name');"
echo "${v_varname}.addColumn('string', 'Type');"
echo "${v_varname}.addColumn('number', 'Container');"
echo "${v_varname}.addColumn('boolean', 'Result');"

echo "${v_varname}.addRows(["

export IFS=";"

v_firstline=1

while read -r c_owner c_name c_type c_conid c_result || [ -n "$c_owner" ]
do
  if [ "${c_result}" != "MATCH" ] # Avoid excessive output
  then
    test $v_firstline -eq 1 || echo "," && v_firstline=0
    echo -e "['${c_owner}', '${c_name}', '${c_type}', ${c_conid}, "\\c
    if [ "${c_result}" = "MATCH" ]
    then
      echo -e "true]"\\c
    elif [ "${c_result}" = "NO MATCH" ]
    then
      echo -e "false]"\\c
    else
      echo -e "null]"\\c
    fi
  fi
done < ${v_sourcecsv}

echo ""
echo ']);'

####