#!/bin/sh
# ----------------------------------------------------------------------------
# Written by Rodrigo Jorge <http://www.dbarj.com.br/>
# Last updated on: Apr/2018 by Rodrigo Jorge
# ----------------------------------------------------------------------------
# If 3 args are given, will get lines of file 1 not in file 2 and print them in file 3.
# If 4 args are given, will get lines of file 1 not in file 2 and print corresponding lines of file 4 in file 3.
set -e # Exit if error. Never remove it.
if [ $# -ne 3 -a $# -ne 4 ]
then
  echo "$0: Three or Four arguments are needed.. given: $#"
  exit 1
fi

SOTYPE=$(uname -s)
if [ "${SOTYPE}" = "SunOS" ]
then
  AWKCMD=gawk
  GREPCMD=/usr/xpg4/bin/grep
  SEDCMD=/usr/xpg4/bin/sed
else
  AWKCMD=awk
  GREPCMD=grep
  SEDCMD=sed
fi

abortscript ()
{
    echo "$1"
	exit 1
}

v_file1="$1"
v_file2="$2"
v_file3="$3"
v_file4="$4"

if [ ! -f "${v_file1}" ]
then
  abortscript "${v_file1} not found."
fi

if [ ! -f "${v_file2}" ]
then
  abortscript "${v_file2} not found."
fi

if [ $# -eq 3 -o "${v_file1}" = "${v_file4}" ]
then

  touch "${v_file3}"

  ## https://stackoverflow.com/questions/18204904/fast-way-of-finding-lines-in-one-file-that-are-not-in-another
  ## https://stackoverflow.com/questions/4366533/how-to-remove-the-lines-which-appear-on-file-b-from-another-file-a

  # Not using comm because file1 can have repeated lines.

  #sort "${v_file1}" > "${v_file1}.ord"
  #sort "${v_file2}" > "${v_file2}.ord"

  #comm -2 -3 "${v_file1}.ord" "${v_file2}.ord" > "${v_file3}"

  #rm -f "${v_file1}.ord" "${v_file2}.ord"

  if [ -s "${v_file2}" ]
  then
    ${AWKCMD} 'NR==FNR{a[$0];next} !($0 in a)' "${v_file2}" "${v_file1}" > "${v_file3}"
  else
    cp "${v_file1}" "${v_file3}"
  fi

else

  if [ ! -f "${v_file4}" ]
  then
    abortscript "${v_file4} not found."
  fi

  touch "${v_file3}"

  # Check if 4th and 1st files are clone. In that case do the same as 3 params.
  checkdiff=$(md5sum "${v_file1}" "${v_file4}" | ${AWKCMD} '{print $1}' | uniq | wc -l)
  if [ ${checkdiff} -eq 1 ]
  then
    if [ -s "${v_file2}" ]
    then
      ${AWKCMD} 'NR==FNR{a[$0];next} !($0 in a)' "${v_file2}" "${v_file1}" > "${v_file3}"
    else
      cp "${v_file1}" "${v_file3}"
    fi
    exit 0
  fi

  ## https://stackoverflow.com/questions/18204904/fast-way-of-finding-lines-in-one-file-that-are-not-in-another
  ## https://stackoverflow.com/questions/4366533/how-to-remove-the-lines-which-appear-on-file-b-from-another-file-a

  # Not using comm because file1 can have repeated lines.

  #sort "${v_file1}" > "${v_file1}.ord"
  #sort "${v_file2}" > "${v_file2}.ord"

  #comm -2 -3 "${v_file1}.ord" "${v_file2}.ord" > "${v_file1}.extra"

  #rm -f "${v_file1}.ord" "${v_file2}.ord"

  if [ ! -s "${v_file2}" ]
  then
    cp "${v_file4}" "${v_file3}"
    exit 0
  fi

  tot_lin_in=$(cat "${v_file1}" | wc -l)

  ${AWKCMD} 'NR==FNR{a[$0];next} !($0 in a)' "${v_file2}" "${v_file1}" > "${v_file1}.extra"
  tot_lin_extra=$(cat "${v_file1}.extra" | wc -l)

  if [ ${tot_lin_in} -eq ${tot_lin_extra} ]
  then
    rm -f "${v_file1}.extra"
    cp "${v_file4}" "${v_file3}"
    exit 0
  fi

  ${GREPCMD} -Fx -n -f "${v_file1}.extra" "${v_file1}" | cut -d':' -f 1 > "${v_file1}.lines"
  
  rm -f "${v_file1}.extra"
  
  ## https://stackoverflow.com/questions/12182910/using-awk-to-pull-specific-lines-from-a-file
  
  #${SEDCMD} 's/$/p/' ${v_file1}.lines | ${SEDCMD} -n -f - ${v_file4} > ${v_file3}
  
  tot_lin_out=$(cat "${v_file1}.lines" | wc -l)
  
  if [ ${tot_lin_in} -eq ${tot_lin_out} ] # Check if this IF is necessary. I think the code will never get here.
  then
    cp "${v_file4}" "${v_file3}"
  else
    ${SEDCMD} 's/^/NR==/' "${v_file1}.lines" | ${AWKCMD} -f - "${v_file4}" > "${v_file3}"
  fi
  
  rm -f "${v_file1}.lines"

fi

exit 0
###