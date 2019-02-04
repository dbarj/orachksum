#!/bin/sh
#****************************************************
#
#    ORACHKSUM - Oracle Database Integrity Checker
#
#****************************************************

echo "Start orachksum collector."

v_param1="$1" # Sections

sh ./moat369/sh/run_all_sids.sh "DEF moat369_param1 = '${v_param1}'"

echo "End orachksum collector."

###