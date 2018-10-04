---------------- START PRETASKS 1 ----------------

-- ----------------------------------------------------------------------------
-- Written by Rodrigo Jorge <http://www.dbarj.com.br/>
-- Last updated on: August/2017 by Rodrigo Jorge
-- ----------------------------------------------------------------------------

-- Variables for orachksum
@@&&fc_def_output_file. orachk_report_file  'report_audit.txt'
@@&&fc_def_output_file. orachk_zip_file     'orachk_audit.zip'

---------------- END PRETASKS 1 ----------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_OBJ_AUDIT_OPTS' 'DBA_OBJ_AUDIT_OPTS'
DEF orachk_subject       = 'Object Audit Options'
DEF orachk_file_pref     = 'obj_audit_opts'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_STMT_AUDIT_OPTS' 'DBA_STMT_AUDIT_OPTS'
DEF orachk_subject       = 'Statement Audit Options'
DEF orachk_file_pref     = 'stmt_audit_opts'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_PRIV_AUDIT_OPTS' 'DBA_PRIV_AUDIT_OPTS'
DEF orachk_subject       = 'Privileges Audit Options'
DEF orachk_file_pref     = 'priv_audit_opts'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_AUDIT_POLICIES' 'DBA_AUDIT_POLICIES'
DEF orachk_subject       = 'Audit Policies'
DEF orachk_file_pref     = 'audit_policies'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_AUDIT_POLICY_COLUMNS' 'DBA_AUDIT_POLICY_COLUMNS'
DEF orachk_subject       = 'Audit Policy Columns'
DEF orachk_file_pref     = 'audit_policy_columns'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'AUDIT_UNIFIED_POLICIES' 'AUDIT_UNIFIED_POLICIES'
DEF orachk_subject       = 'Audit Unified Policies'
DEF orachk_file_pref     = 'audit_unified_policies'
DEF orachk_srczip_pref   = 'audit'
DEF orachk_sql_file      = 'create_csv_db_audit_unified_policies.sql'
DEF orachk_comp_column   = ''
@@&&skip_ver_le_11.&&orachksum_fc_run_check_tables.

---------------- START POSTTASKS 1 ----------------

HOS zip -mjT &&orachk_zip_file. &&orachk_report_file.  >> &&moat369_log3.

@@&&fc_ren_output_file. orachk_zip_file
@@&&fc_encrypt_file. orachk_zip_file
HOS zip -mjT &&moat369_zip_filename. &&orachk_zip_file. >> &&moat369_log3.

-- Reset Variables for orachksum
UNDEF orachk_report_file
UNDEF orachk_zip_file

---------------- END POSTTASKS 1 ----------------