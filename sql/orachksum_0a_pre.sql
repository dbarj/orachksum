-- Put here any customization that you want to load always before starting the sections.
-- Note it will load only once in the beggining.

-- Checksum Dir Files
DEF orachk_workdir = '&&moat369_sw_base./main'
DEF orachk_exec_sh = '&&orachk_workdir./sql/exec_sh.sql'

-- Define Debug file
@@&&fc_def_output_file. orachk_dbgzip_file  'orachk_debug.zip'
@@&&fc_def_output_file. orachk_shexec_log   'shexec.log'
@@&&fc_seq_output_file. orachk_shexec_log

-- Create Version file
@@&&fc_def_output_file. orachk_version_file  'version.txt'
@@&&fc_seq_output_file. orachk_version_file

-- Check Oracle PSU/BP/OJVM information.
@@&&fc_spool_start.
@@&&orachk_workdir./sql/get_oracle_version.sql &&orachk_version_file.
@@&&fc_spool_end.

@@&&fc_def_output_file. orachk_vers_def_file 'version_def.sql'
@@&&orachk_exec_sh &&orachk_workdir./sh/def_oracle_version.sh &&orachk_version_file. &&orachk_vers_def_file.
@@&&orachk_vers_def_file.

@@&&fc_set_value_var_nvl2. 'orachk_skipif_unsupported' '&&orachk_ver_oraversion.' '' '&&fc_skip_script.'

-- Check orachk_method value
SET TERM ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  V_VAR         VARCHAR2(30)  := 'orachk_method';
  V_VAR_CONTENT VARCHAR2(500) := '&&orachk_method.';
BEGIN
  IF V_VAR_CONTENT NOT IN ('csv','fast') THEN
    RAISE_APPLICATION_ERROR(-20000, 'Invalid value for ' || V_VAR || ': "' || V_VAR_CONTENT || '" in 00_config.sql. Valid values are "csv" or "fast".');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE
@@&&fc_set_term_off.

-- TODO - Check if fast mode selected and connected hostname not the same as DB hostname

-- Define custom orachksum functions
DEF orachksum_fc_run_check_hash    = '&&moat369_sw_folder./orachksum_fc_run_check_hash_&&orachk_method..sql'
DEF orachksum_fc_run_check_tables  = '&&moat369_sw_folder./orachksum_fc_run_check_tables_&&orachk_method..sql'
DEF orachksum_fc_gen_orig_table    = '&&moat369_sw_folder./orachksum_fc_gen_orig_table_&&orachk_method..sql'

-- Default Users and Roles

-- Split due to 200 char limit
DEF default_user_list_11g_1 = "('ANONYMOUS','APEX_030200','APEX_PUBLIC_USER','APPQOSSYS','CTXSYS','DBSNMP','DIP','DVF','DVSYS','EXFSYS','FLOWS_FILES','LBACSYS','MDDATA','MDSYS','MGMT_VIEW','OLAPSYS','ORACLE_OCM')";
DEF default_user_list_11g_2 = "('ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','OWBSYS_AUDIT','SI_INFORMTN_SCHEMA','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','SYS','SYSMAN','SYSTEM','WMSYS','XDB','XS$NULL')";
--
DEF default_role_list_11g_1 = "('ADM_PARALLEL_EXECUTE_TASK','APEX_ADMINISTRATOR_ROLE','AQ_ADMINISTRATOR_ROLE','AQ_USER_ROLE','AUTHENTICATEDUSER','CONNECT','CSW_USR_ROLE','CTXAPP','CWM_USER','DATAPUMP_EXP_FULL_DATABASE')";
DEF default_role_list_11g_2 = "('DATAPUMP_IMP_FULL_DATABASE','DBA','DBFS_ROLE','DELETE_CATALOG_ROLE','DV_ACCTMGR','DV_ADMIN','DV_AUDIT_CLEANUP','DV_GOLDENGATE_ADMIN','DV_GOLDENGATE_REDO_ACCESS','DV_MONITOR','DV_OWNER')";
DEF default_role_list_11g_3 = "('DV_PATCH_ADMIN','DV_PUBLIC','DV_REALM_OWNER','DV_REALM_RESOURCE','DV_SECANALYST','DV_STREAMS_ADMIN','DV_XSTREAM_ADMIN','EJBCLIENT','EXECUTE_CATALOG_ROLE','EXP_FULL_DATABASE')";
DEF default_role_list_11g_4 = "('GATHER_SYSTEM_STATISTICS','GLOBAL_AQ_USER_ROLE','HS_ADMIN_EXECUTE_ROLE','HS_ADMIN_ROLE','HS_ADMIN_SELECT_ROLE','IMP_FULL_DATABASE','JAVADEBUGPRIV','JAVAIDPRIV','JAVASYSPRIV','JAVAUSERPRIV')";
DEF default_role_list_11g_5 = "('JAVA_ADMIN','JAVA_DEPLOY','JMXSERVER','LBAC_DBA','LOGSTDBY_ADMINISTRATOR','MGMT_USER','OEM_ADVISOR','OEM_MONITOR','OLAP_DBA','OLAP_USER','OLAP_XS_ADMIN','ORDADMIN','OWB$CLIENT')";
DEF default_role_list_11g_6 = "('OWB_DESIGNCENTER_VIEW','OWB_USER','RECOVERY_CATALOG_OWNER','RESOURCE','SCHEDULER_ADMIN','SELECT_CATALOG_ROLE','SPATIAL_CSW_ADMIN','SPATIAL_WFS_ADMIN','WFS_USR_ROLE','WM_ADMIN_ROLE','XDBADMIN')";
DEF default_role_list_11g_7 = "('XDB_SET_INVOKER','XDB_WEBSERVICES','XDB_WEBSERVICES_OVER_HTTP','XDB_WEBSERVICES_WITH_PUBLIC')";
DEF default_role_list_11g_8 = "(' ')";
DEF default_role_list_11g_9 = "(' ')";

-- Binaries for SunOS
COL cmd_find NEW_V cmd_find

SELECT bin_prefix2 || 'find' cmd_find
from (
SELECT
decode(platform_id,
1,'/usr/xpg4/bin/', -- Solaris[tm] OE (32-bit)
2,'/usr/xpg4/bin/', -- Solaris[tm] OE (64-bit)
'') bin_prefix1,
decode(platform_id,
1,'/usr/gnu/bin/', -- Solaris[tm] OE (32-bit)
2,'/usr/gnu/bin/', -- Solaris[tm] OE (64-bit)
'') bin_prefix2 from v$database);

COL cmd_find NEW_V clear

-- If version is 12.2, change array size to avoid bug.

@@&&fc_def_output_file. orachk_step_file 'orachk_step_file.sql'
@@&&fc_spool_start.
SPO &&orachk_step_file.
PRO DEF fc_reset_defs_orig = '&&fc_reset_defs.'
PRO DEF fc_reset_defs      = '&&moat369_sw_folder./orachksum_fc_reset_defs.sql'
PRO SET ARRAY 999
SPO OFF
@@&&fc_spool_end.
@@&&skip_ver_le_12_1.&&skip_ver_ge_18.&&orachk_step_file.
HOS rm -f &&orachk_step_file.
UNDEF orachk_step_file

---- Check if DatabaseVault tables exist

COL orachk_skip_db_vault NEW_V orachk_skip_db_vault
select DECODE(COUNT(*),0,'--') orachk_skip_db_vault from dba_objects where owner='DVSYS' and object_name='DBA_DV_REALM';

---- Create objects for FAST EXECUTION MODE

@@&&fc_def_output_file. orachk_step_file 'orachk_step_file.sql'
@@&&fc_spool_start.
SPO &&orachk_step_file.
SELECT '@@' || DECODE('&&orachk_method.','fast','','&&fc_skip_script.') || '&&moat369_sw_folder./orachksum_fc_fast_exttables_create.sql' FROM DUAL;
SPO OFF
@@&&fc_spool_end.
@@&&orachk_step_file.
HOS rm -f &&orachk_step_file.
UNDEF orachk_step_file
