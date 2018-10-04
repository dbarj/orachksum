-- THIS SCRIPT REQUIRES THAT THE FOLLOWING VARIABLES ARE ALREADY SET:
-- orachk_file_pref
-- orachk_srczip_pref
-- orachk_orig_file
-- orachk_report_file
-- orachk_comp_column
-- orachk_zip_file

-- Defined in pre-sql:
-- orachk_exec_sh
-- orachk_workdir
-- orachk_version_file
-- orachk_ver_pdbs

-- Defined during this script:
-- orachk_orig_red_file
-- orachk_ncol_def_file
-- orachk_tab_con_id_col

-- BEGIN

@@&&fc_def_empty_var. orachk_comp_incl_root
@@&&fc_set_value_var_nvl. 'orachk_comp_incl_root' '&&orachk_comp_incl_root.' 'N'

@@&&fc_def_output_file. orachk_orig_red_file '&&orachk_file_pref._orig_red.csv'
@@&&fc_def_output_file. orachk_ncol_def_file '&&orachk_file_pref._ncol_def.sql'

-- Define column values.
@@&&orachk_exec_sh &&orachk_workdir./sh/def_tab_num_cols.sh &&orachk_workdir. &&orachk_file_pref. &&orachk_ncol_def_file. &&orachk_comp_column.
@@&&orachk_ncol_def_file

-- Generate CSV to compare.
@@&&orachk_exec_sh &&orachk_workdir./sh/call_reduce_tbl.sh &&orachk_workdir. &&orachk_version_file. &&orachk_orig_red_file. &&orachk_report_file. &&orachk_file_pref. &&orachk_srczip_pref. &&orachk_comp_column.
@@&&orachk_exec_sh &&orachk_workdir./sh/csv_expand.sh &&orachk_workdir. &&orachk_orig_red_file. &&orachk_orig_file. &&orachk_tab_con_id_col. &&orachk_comp_incl_root. &&orachk_ver_pdbs.

-- Sort files
-- HOS sort &&orachk_orig_file. > &&orachk_orig_file..2
-- HOS mv &&orachk_orig_file..2 &&orachk_orig_file.

HOS zip -mjT &&orachk_zip_file. &&orachk_orig_red_file. >> &&moat369_log3.
HOS zip -mjT &&orachk_zip_file. &&orachk_ncol_def_file. >> &&moat369_log3.

UNDEF orachk_orig_red_file
UNDEF orachk_ncol_def_file
UNDEF orachk_comp_incl_root

-- END