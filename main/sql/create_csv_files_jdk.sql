HOS ( cd $ORACLE_HOME; &&cmd_find. -type f -path "./jdk/*" -exec sha256sum "{}" + ) > "&&1."
HOS cat "&&1." | &&cmd_awk. '{print substr($0,67)",,"toupper(substr($0,1,64))}' > "&&1..2"
HOS mv "&&1..2" "&&1."
-- TODO: Consider scenario where filename has ',' or '"'