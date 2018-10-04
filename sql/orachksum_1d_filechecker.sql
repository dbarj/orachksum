---------------- START PRETASKS 1 ----------------

-- ----------------------------------------------------------------------------
-- Written by Rodrigo Jorge <http://www.dbarj.com.br/>
-- ----------------------------------------------------------------------------

-- Variables for orachksum
DEF orachk_file_pref      = 'files'
DEF orachk_srczip_pref    = 'files'
DEF orachk_comp_column    = ''
DEF orachk_comp_incl_root = 'Y'

@@&&fc_def_output_file. orachk_report_file  'report_files.txt'
@@&&fc_def_output_file. orachk_zip_file     'orachk_files.zip'

@@&&fc_def_output_file. orachk_orig_file     '&&orachk_file_pref._orig.csv'

-- Generate Orig Table for compare
@@&&orachksum_fc_gen_orig_table.

---------------- END PRETASKS 1 ----------------

DEF orachk_subject       = 'Files: ./rdbms/*'
DEF orachk_file_pref     = 'files'
DEF orachk_sql_file      = 'create_csv_files_rdbms.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_hash.

--------------

DEF orachk_subject       = 'Files: ./jdk/*'
DEF orachk_file_pref     = 'files'
DEF orachk_sql_file      = 'create_csv_files_jdk.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_hash.

--------------

DEF orachk_subject       = 'Files: ./javavm/*'
DEF orachk_file_pref     = 'files'
DEF orachk_sql_file      = 'create_csv_files_javavm.sql'
DEF orachk_comp_column   = ''
@@&&orachksum_fc_run_check_hash.

---------------- START POSTTASKS 1 ----------------

HOS zip -mjT &&orachk_zip_file. &&orachk_report_file.   >> &&moat369_log3.
HOS zip -mjT &&orachk_zip_file. &&orachk_orig_file.     >> &&moat369_log3.

@@&&fc_ren_output_file. orachk_zip_file
@@&&fc_encrypt_file. orachk_zip_file
HOS zip -mjT &&moat369_zip_filename. &&orachk_zip_file. >> &&moat369_log3.

-- Reset Variables for orachksum
UNDEF orachk_orig_file
UNDEF orachk_report_file
UNDEF orachk_zip_file
UNDEF orachk_comp_incl_root
UNDEF orachk_step_code_driver

---------------- END POSTTASKS 1 ----------------
