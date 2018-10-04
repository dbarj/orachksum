---------------- START PRETASKS 1 ----------------

-- ----------------------------------------------------------------------------
-- Written by Rodrigo Jorge <http://www.dbarj.com.br/>
-- Last updated on: August/2017 by Rodrigo Jorge
-- ----------------------------------------------------------------------------

-- Variables for orachksum
@@&&fc_def_output_file. orachk_report_file  'report_audit.txt'
@@&&fc_def_output_file. orachk_zip_file     'orachk_audit.zip'

---------------- END PRETASKS 1 ----------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'DBA_DV_REALM' 'DBA_DV_REALM'
DEF orachk_subject       = 'DV Realm'
DEF orachk_file_pref     = 'obj_audit_opts'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
--@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'DBA_DV_REALM_AUTH' 'DBA_DV_REALM_AUTH'
DEF orachk_subject       = 'DV Realm Auth'
DEF orachk_file_pref     = 'stmt_audit_opts'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
--@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'DBA_DV_REALM_OBJECT' 'DBA_DV_REALM_OBJECT'
DEF orachk_subject       = 'DV Realm Object'
DEF orachk_file_pref     = 'stmt_audit_opts'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
--@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'DBA_DV_RULE' 'DBA_DV_RULE'
DEF orachk_subject       = 'DV Rule'
DEF orachk_file_pref     = 'stmt_audit_opts'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
--@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'DBA_DV_RULE_SET' 'DBA_DV_RULE_SET'
DEF orachk_subject       = 'DV Rule Set'
DEF orachk_file_pref     = 'stmt_audit_opts'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
--@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'DBA_DV_COMMAND_RULE' 'DBA_DV_COMMAND_RULE'
DEF orachk_subject       = 'DV Command Rule'
DEF orachk_file_pref     = 'stmt_audit_opts'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
--@@&&orachksum_fc_run_check_tables.

---------------- START POSTTASKS 1 ----------------

HOS zip -mjT &&orachk_zip_file. &&orachk_report_file.  >> &&moat369_log3.

@@&&fc_ren_output_file. orachk_zip_file
@@&&fc_encrypt_file. orachk_zip_file
HOS zip -mjT &&moat369_zip_filename. &&orachk_zip_file. >> &&moat369_log3.

-- Reset Variables for orachksum
UNDEF orachk_report_file
UNDEF orachk_zip_file

---------------- END POSTTASKS 1 ----------------

-- DBA_DV_AUTH
-- DBA_DV_CODE
---- DBA_DV_COMMAND_RULE
-- DBA_DV_DATAPUMP_AUTH
-- DBA_DV_DDL_AUTH
-- DBA_DV_DICTIONARY_ACCTS
-- DBA_DV_FACTOR
-- DBA_DV_FACTOR_LINK
-- DBA_DV_FACTOR_TYPE
-- DBA_DV_IDENTITY
-- DBA_DV_IDENTITY_MAP
-- DBA_DV_JOB_AUTH
-- DBA_DV_MAC_POLICY
-- DBA_DV_MAC_POLICY_FACTOR
-- DBA_DV_ORADEBUG
-- DBA_DV_PATCH_ADMIN_AUDIT
-- DBA_DV_POLICY_LABEL
-- DBA_DV_PROXY_AUTH
-- DBA_DV_PUB_PRIVS
---- DBA_DV_REALM
---- DBA_DV_REALM_AUTH
---- DBA_DV_REALM_OBJECT
-- DBA_DV_ROLE
---- DBA_DV_RULE
---- DBA_DV_RULE_SET
-- DBA_DV_RULE_SET_RULE
-- DBA_DV_STATUS
-- DBA_DV_TTS_AUTH
-- DBA_DV_USER_PRIVS
-- DBA_DV_USER_PRIVS_ALL
