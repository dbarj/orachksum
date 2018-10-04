-- This code will skip execute a shell command and save the output for debug.
-- Depends that orachk_dbgzip_file is defined 
SET TERM OFF
DEF c_cmd_script_1  = '&&1.'

@@&&fc_def_empty_var. 2
@@&&fc_def_empty_var. 3
@@&&fc_def_empty_var. 4
@@&&fc_def_empty_var. 5
@@&&fc_def_empty_var. 6
@@&&fc_def_empty_var. 7
@@&&fc_def_empty_var. 8
@@&&fc_def_empty_var. 9
@@&&fc_def_empty_var. 10

DEF c_cmd_script_2  = '&&2.'
DEF c_cmd_script_3  = '&&3.'
DEF c_cmd_script_4  = '&&4.'
DEF c_cmd_script_5  = '&&5.'
DEF c_cmd_script_6  = '&&6.'
DEF c_cmd_script_7  = '&&7.'
DEF c_cmd_script_8  = '&&8.'
DEF c_cmd_script_9  = '&&9.'
DEF c_cmd_script_10 = '&&10.'

UNDEF 1 2 3 4 5 6 7 8 9 10

@@&&fc_def_empty_var. orachk_file_pref

@@&&fc_set_value_var_decode. orachk_sh_debug  '&&DEBUG.' 'ON' '-x' '+x'

@@&&fc_set_value_var_nvl. orachk_file_pref  '&&orachk_file_pref.' 'exec_shell'

@@&&fc_set_term_off.

@@&&fc_def_output_file. orachk_shexec_file  'orachk_shexec.sql'

@@&&fc_gen_temp_file. orachk_dbg_file  &&orachk_file_pref._dbg txt

@@&&fc_spool_start.
SPOOL &&orachk_shexec_file.
SELECT regexp_replace('HOS sh &&orachk_sh_debug. &&c_cmd_script_1. &&c_cmd_script_2. &&c_cmd_script_3. &&c_cmd_script_4. &&c_cmd_script_5. &&c_cmd_script_6. &&c_cmd_script_7. &&c_cmd_script_8. &&c_cmd_script_9. &&c_cmd_script_10. >> &&orachk_dbg_file. 2>> &&orachk_dbg_file.',' +',' ')
  FROM DUAL
/
SPOOL OFF
@@&&fc_spool_end.

EXEC :get_time_t0 := DBMS_UTILITY.get_time;
@&&orachk_shexec_file.
EXEC :get_time_t1 := DBMS_UTILITY.get_time;

@@&&fc_spool_start.
SPOOL &&orachk_shexec_log. APP
SELECT TO_CHAR(SYSDATE, '&&moat369_date_format.')||','||
       TO_CHAR((:get_time_t1 - :get_time_t0)/100, '999,990.00')||'s,'||
       regexp_replace('sh &&orachk_sh_debug. &&c_cmd_script_1. &&c_cmd_script_2. &&c_cmd_script_3. &&c_cmd_script_4. &&c_cmd_script_5. &&c_cmd_script_6. &&c_cmd_script_7. &&c_cmd_script_8. &&c_cmd_script_9. &&c_cmd_script_10. >> &&orachk_dbg_file. 2>> &&orachk_dbg_file.',' +',' ')
  FROM DUAL
/
SPOOL OFF
@@&&fc_spool_end.

PRO zip -mjT &&orachk_dbgzip_file. &&orachk_dbg_file. >> &&moat369_log3.
HOS zip -mjT &&orachk_dbgzip_file. &&orachk_dbg_file. >> &&moat369_log3.
HOS rm -f &&orachk_shexec_file.

UNDEF orachk_sh_debug orachk_dbg_file orachk_shexec_file

UNDEF c_cmd_script_1 c_cmd_script_2 c_cmd_script_3 c_cmd_script_4 c_cmd_script_5 c_cmd_script_6 c_cmd_script_7 c_cmd_script_8 c_cmd_script_9 c_cmd_script_10