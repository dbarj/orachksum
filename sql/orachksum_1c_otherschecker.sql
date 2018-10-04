---------------- START PRETASKS 1 ----------------

-- ----------------------------------------------------------------------------
-- Written by Rodrigo Jorge <http://www.dbarj.com.br/>
-- ----------------------------------------------------------------------------

-- Variables for orachksum
@@&&fc_def_output_file. orachk_report_file  'report_others.txt'
@@&&fc_def_output_file. orachk_zip_file     'orachk_others.zip'

---------------- END PRETASKS 1 ----------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_SYNONYMS' 'DBA_SYNONYMS'
DEF orachk_subject       = 'Synonyms'
DEF orachk_file_pref     = 'synonyms'
DEF orachk_srczip_pref   = 'synonyms'
DEF orachk_sql_file      = 'create_csv_db_synonym.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_JAVA_POLICY' 'DBA_JAVA_POLICY'
DEF orachk_subject       = 'Java Policy'
DEF orachk_file_pref     = 'java_pol'
DEF orachk_srczip_pref   = 'java_pol'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_TS_QUOTAS' 'DBA_TS_QUOTAS'
DEF orachk_subject       = 'Tablespace Quotas'
DEF orachk_file_pref     = 'ts_quotas'
DEF orachk_srczip_pref   = 'ts_quotas'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_POLICIES' 'DBA_POLICIES'
DEF orachk_subject       = 'VPD Policies'
DEF orachk_file_pref     = 'policies'
DEF orachk_srczip_pref   = 'policies'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_TRIGGERS' 'DBA_TRIGGERS'
DEF orachk_subject       = 'Triggers'
DEF orachk_file_pref     = 'triggers'
DEF orachk_srczip_pref   = 'triggers'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
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