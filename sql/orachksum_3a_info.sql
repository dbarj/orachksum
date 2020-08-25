----------------------------------------

DEF title = 'Instance'
DEF main_table = 'gv$instance'
@@&&fc_gen_select_star_query. '&&main_table.' 'sql_text'
@@&&9a_pre_one.

----------------------------------------

DEF title = 'Registry'
@@&&fc_set_value_var_decode. 'main_table' '&&is_cdb.' 'Y' 'CDB_REGISTRY' 'DBA_REGISTRY'
@@&&fc_gen_select_star_query. '&&main_table.' 'sql_text'
@@&&9a_pre_one.

----------------------------------------

DEF title = 'Registry Schemas'
@@&&fc_set_value_var_decode. 'main_table' '&&is_cdb.' 'Y' 'CDB_REGISTRY_SCHEMAS' 'DBA_REGISTRY_SCHEMAS'
@@&&fc_gen_select_star_query. '&&main_table.' 'sql_text'
@@&&skip_ver_le_12_1.&&9a_pre_one.

----------------------------------------

DEF title = 'Registry History'
@@&&fc_set_value_var_decode. 'main_table' '&&is_cdb.' 'Y' 'CDB_REGISTRY_HISTORY' 'DBA_REGISTRY_HISTORY'
@@&&fc_gen_select_star_query. '&&main_table.' 'sql_text'
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'Registry SQLPatch'
@@&&fc_set_value_var_decode. 'main_table' '&&is_cdb.' 'Y' 'CDB_REGISTRY_SQLPATCH' 'DBA_REGISTRY_SQLPATCH'
@@&&fc_gen_select_star_query. '&&main_table.' 'sql_text'
@@&&skip_ver_le_11.&&9a_pre_one.

-----------------------------------------

DEF title = 'Registry SQLPatch RU Info'
@@&&fc_set_value_var_decode. 'main_table' '&&is_cdb.' 'Y' 'CDB_REGISTRY_SQLPATCH_RU_INFO' 'DBA_REGISTRY_SQLPATCH_RU_INFO'
@@&&fc_gen_select_star_query. '&&main_table.' 'sql_text'
@@&&skip_ver_le_12.&&9a_pre_one.

-----------------------------------------

DEF title = 'OPatch lspatches'
@@&&fc_def_output_file. out_filename 'opatch_lspatches.txt'

HOS $ORACLE_HOME/OPatch/opatch lspatches > &&out_filename.

DEF one_spool_text_file = '&&out_filename.'
DEF one_spool_text_file_rename = 'Y'
DEF skip_html = '--'
DEF skip_text_file = ''
EXEC :sql_text := '$ opatch lspatches';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'OPatch lsinv details'
@@&&fc_def_output_file. out_filename 'opatch_lsinv_details.txt'

HOS $ORACLE_HOME/OPatch/opatch lsinv -details > &&out_filename.

DEF one_spool_text_file = '&&out_filename.'
DEF one_spool_text_file_rename = 'Y'
DEF skip_html = '--'
DEF skip_text_file = ''
EXEC :sql_text := '$ opatch lsinv -details';
@@&&9a_pre_one.

-----------------------------------------

DEF title = 'OPatch lsinv all'
@@&&fc_def_output_file. out_filename 'opatch_lsinv_all.txt'

HOS $ORACLE_HOME/OPatch/opatch lsinv -all > &&out_filename.

DEF one_spool_text_file = '&&out_filename.'
DEF one_spool_text_file_rename = 'Y'
DEF skip_html = '--'
DEF skip_text_file = ''
EXEC :sql_text := '$ opatch lsinv -all';
@@&&9a_pre_one.

-----------------------------------------

UNDEF out_filename