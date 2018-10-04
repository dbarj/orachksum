---------------- START PRETASKS 1 ----------------

-- ----------------------------------------------------------------------------
-- Written by Rodrigo Jorge <http://www.dbarj.com.br/>
-- Last updated on: August/2017 by Rodrigo Jorge
-- ----------------------------------------------------------------------------

-- Variables for orachksum
@@&&fc_def_output_file. orachk_report_file  'report_sched.txt'
@@&&fc_def_output_file. orachk_zip_file     'orachk_sched.zip'

---------------- END PRETASKS 1 ----------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_JOBS' 'DBA_JOBS'
DEF orachk_subject       = 'Legacy Jobs'
DEF orachk_file_pref     = 'legacy_jobs'
DEF orachk_srczip_pref   = 'sched'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_SCHEDULER_JOBS' 'DBA_SCHEDULER_JOBS'
DEF orachk_subject       = 'Scheduler Jobs'
DEF orachk_file_pref     = 'jobs'
DEF orachk_srczip_pref   = 'sched'
DEF orachk_sql_file      = 'create_csv_db_generic.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_tables.

--------------

@@&&fc_set_value_var_decode. orachk_table_name '&&is_ver_ge_12.' 'Y' 'CDB_SCHEDULER_PROGRAMS' 'DBA_SCHEDULER_PROGRAMS'
DEF orachk_subject       = 'Scheduler Programs'
DEF orachk_file_pref     = 'programs'
DEF orachk_srczip_pref   = 'sched'
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