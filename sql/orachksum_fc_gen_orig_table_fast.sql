-- THIS SCRIPT REQUIRES THAT THE FOLLOWING VARIABLES ARE ALREADY SET:
-- orachk_file_pref
-- orachk_srczip_pref
-- orachk_orig_file
-- orachk_comp_column
-- orachk_comp_incl_root

-- Defined in pre-sql:
-- orachk_path_tabfile1
-- orachk_exec_sh
-- orachk_workdir
-- orachk_ver_oraversion
-- orachk_ver_ps_type
-- orachk_ver_ps_value
-- orachk_ver_ojvmpsu
-- orachk_ver_pdbs

-- Defined during this script:
-- orachk_tab_numcols_csv
-- orachk_orig_raw_file
-- orachk_orig_red_file
-- orachk_ncol_def_file

-- BEGIN

@@&&fc_def_empty_var. orachk_comp_incl_root
@@&&fc_set_value_var_nvl. 'orachk_comp_incl_root' '&&orachk_comp_incl_root.' 'N'

@@&&fc_def_output_file. orachk_orig_raw_file '&&orachk_file_pref._orig_raw.csv'
@@&&fc_def_output_file. orachk_orig_red_file '&&orachk_file_pref._orig_red.csv'
@@&&fc_def_output_file. orachk_ncol_def_file '&&orachk_file_pref._ncol_def.sql'

-- Define column values.
@@&&orachk_exec_sh &&orachk_workdir./sh/def_tab_num_cols.sh &&orachk_workdir. &&orachk_file_pref. &&orachk_ncol_def_file. &&orachk_comp_column.
@@&&orachk_ncol_def_file

-- Generate original reduced file.
HOS touch &&orachk_orig_raw_file.
@@&&orachk_skipif_unsupported.&&orachk_exec_sh &&orachk_workdir./sh/unzip_orig_db_csv.sh &&orachk_workdir. &&orachk_ver_oraversion. &&orachk_file_pref. &&orachk_srczip_pref. &&orachk_orig_raw_file.
HOS mv &&orachk_orig_raw_file. &&orachk_path_tabfile1.
@@&&orachk_workdir./sql/gen_sql_text_reduce.sql '&&orachk_ver_oraversion.' '&&orachk_ver_ps_type.' '&&orachk_ver_ps_value.' '&&orachk_ver_ojvmpsu.' '&&orachk_tab_numcols_csv.'
@@&&orachk_workdir./sql/create_csv_from_sql.sql '&&orachk_orig_red_file.' '&&orachk_tab_numcols_csv.'
HOS mv &&orachk_path_tabfile1. &&orachk_orig_raw_file.

-- Expand reduced file.
HOS mv &&orachk_orig_red_file. &&orachk_path_tabfile1.
@@&&orachk_workdir./sql/gen_sql_text_expand.sql '&&orachk_ver_pdbs.' '&&orachk_tab_numcols_csv.' '&&orachk_tab_con_id_col.' '&&orachk_comp_incl_root.'
@@&&orachk_workdir./sql/create_csv_from_sql.sql '&&orachk_orig_file.' '&&orachk_tab_numcols_csv.'
HOS mv &&orachk_path_tabfile1. &&orachk_orig_red_file.

HOS zip -mjT &&orachk_zip_file. &&orachk_orig_red_file. >> &&moat369_log3.
HOS zip -mjT &&orachk_zip_file. &&orachk_ncol_def_file. >> &&moat369_log3.
HOS rm -f &&orachk_orig_raw_file.

UNDEF orachk_orig_raw_file
UNDEF orachk_orig_red_file
UNDEF orachk_ncol_def_file
UNDEF orachk_comp_incl_root

-- END