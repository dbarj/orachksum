-- Put here any customization that you want to load always after executing the sections.
-- Note it will load only once in the end.
UNDEF orachk_workdir
UNDEF orachk_exec_sh

-- Rename and zip Version file
@@&&fc_zip_driver_files. &&orachk_version_file.
@@&&fc_zip_driver_files. &&orachk_vers_def_file.
@@&&fc_zip_driver_files. &&orachk_shexec_log.
UNDEF orachk_version_file orachk_vers_def_file orachk_shexec_log

-- Debug File
@@&&fc_ren_output_file. orachk_dbgzip_file
@@&&fc_encrypt_file. orachk_dbgzip_file
HOS zip -mjT &&moat369_zip_filename. &&orachk_dbgzip_file. >> &&moat369_log3.

UNDEF orachk_ver_oraversion 
UNDEF orachk_ver_ps_type
UNDEF orachk_ver_ps_value
UNDEF orachk_ver_ojvmpsu
UNDEF orachk_ver_pdbs

UNDEF orachk_skipif_unsupported

UNDEF orachksum_fc_run_check_hash
-- UNDEF orachksum_fc_run_check_sha256
UNDEF orachksum_fc_run_check_tables
UNDEF orachksum_fc_run_check_exponly
UNDEF orachksum_fc_gen_orig_table

DECLARE
  V_ORA_VER_MAJOR NUMBER;
  V_ORA_VERSION   VARCHAR2(20);
BEGIN
  select substr(version,1,instr(version,'.',1,4)-1),substr(version,1,instr(version,'.',1,1)-1) into v_ora_version,v_ora_ver_major from sys.v$instance;
  IF v_ora_version IN ('12.1.0.1','12.1.0.2') THEN
    execute immediate 'alter session reset exclude_seed_cdb_view';
  ELSIF v_ora_ver_major >= 12 THEN
    execute immediate 'alter session reset "_exclude_seed_cdb_view"';
  END IF;
END;
/

UNDEF default_user_list_11g_1
UNDEF default_user_list_11g_2
--
UNDEF default_role_list_11g_1
UNDEF default_role_list_11g_2
UNDEF default_role_list_11g_3
UNDEF default_role_list_11g_4
UNDEF default_role_list_11g_5
UNDEF default_role_list_11g_6
UNDEF default_role_list_11g_7
UNDEF default_role_list_11g_8
UNDEF default_role_list_11g_9

UNDEF cmd_find

---- Clean objects of FAST EXECUTION MODE

@@&&fc_def_output_file. orachk_step_file 'orachk_step_file.sql'
@@&&fc_spool_start.
SPOOL &&orachk_step_file.
SELECT '@@' || DECODE('&&orachk_method.','fast','','&&fc_skip_script.') || '&&moat369_sw_folder./orachksum_fc_fast_exttables_drop.sql' FROM DUAL;
SPOOL OFF
@@&&fc_spool_end.
@@&&orachk_step_file.
HOS rm -f &&orachk_step_file.
UNDEF orachk_step_file

UNDEF orachk_method
--