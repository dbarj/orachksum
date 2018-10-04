---------------- START PRETASKS 1 ----------------

-- ----------------------------------------------------------------------------
-- Written by Rodrigo Jorge <http://www.dbarj.com.br/>
-- Last updated on: August/2017 by Rodrigo Jorge
-- ----------------------------------------------------------------------------

-- Variables for orachksum
@@&&fc_def_output_file. orachk_report_file  'report.txt'
@@&&fc_def_output_file. orachk_zip_file     'orachk_privs.zip'

---------------- END PRETASKS 1 ----------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_TAB_PRIVS' 'DBA_TAB_PRIVS'
DEF orachk_subject       = 'Table Privs'
DEF orachk_file_pref     = 'privs_tab'
DEF orachk_srczip_pref   = 'privs'
DEF orachk_sql_file      = 'create_csv_db_privs.sql'
DEF orachk_comp_column   = '3,9'
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_TAB_PRIVS' 'DBA_TAB_PRIVS'
DEF orachk_subject       = 'Table Privs (Non-Internals)'
DEF orachk_file_pref     = 'privs_tab_others'
DEF orachk_srczip_pref   = 'privs'
DEF orachk_sql_file      = 'create_csv_db_privs.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_COL_PRIVS' 'DBA_COL_PRIVS'
DEF orachk_subject       = 'Column Privs'
DEF orachk_file_pref     = 'privs_col'
DEF orachk_srczip_pref   = 'privs'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_SYS_PRIVS' 'DBA_SYS_PRIVS'
DEF orachk_subject       = 'System Privs'
DEF orachk_file_pref     = 'privs_sys'
DEF orachk_srczip_pref   = 'privs'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_ROLE_PRIVS' 'DBA_ROLE_PRIVS'
DEF orachk_subject       = 'Role Privs'
DEF orachk_file_pref     = 'privs_rol'
DEF orachk_srczip_pref   = 'privs'
DEF orachk_sql_file      = 'create_csv_db_privs.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_ROLE_PRIVS' 'DBA_ROLE_PRIVS'
DEF orachk_subject       = 'Role Privs (Non-Internals)'
DEF orachk_file_pref     = 'privs_rol_others'
DEF orachk_srczip_pref   = 'privs'
DEF orachk_sql_file      = 'create_csv_db_privs.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

---------------- START POSTTASKS 1 ----------------

HOS zip -mjT &&orachk_zip_file. &&orachk_report_file.  >> &&moat369_log3.

@@&&fc_ren_output_file. orachk_zip_file
@@&&fc_encrypt_file. orachk_zip_file
HOS zip -mjT &&moat369_zip_filename. &&orachk_zip_file. >> &&moat369_log3.

-- Reset Variables for orachksum
UNDEF orachk_report_file
UNDEF orachk_zip_file

---------------- END POSTTASKS 1 ----------------