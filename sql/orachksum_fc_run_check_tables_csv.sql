-- ----------------------------------------------------------------------------
-- Written by Rodrigo Jorge <http://www.dbarj.com.br/>
-- Last updated on: November/2017 by Rodrigo Jorge
-- ----------------------------------------------------------------------------

DEF title = '&&orachk_subject. - Extra';
DEF main_table = '&&orachk_table_name.'

@@&&fc_def_output_file. orachk_db_file       '&&orachk_file_pref._db_out.csv'
@@&&fc_def_output_file. orachk_orig_file     '&&orachk_file_pref._orig.csv'

@@&&fc_def_output_file. orachk_tot_rows_db   '&&orachk_file_pref._csv_numrows_db.sql'
@@&&fc_def_output_file. orachk_tot_rows_orig '&&orachk_file_pref._csv_numrows_orig.sql'

-- If orachk_comp_column is defined, will generate the compare file and use it on orachksum shell step. Otherwise, ignore.
@@&&fc_def_output_file. orachk_db_comp       '&&orachk_file_pref._db_out.comp.csv'
@@&&fc_def_output_file. orachk_orig_comp     '&&orachk_file_pref._orig.comp.csv'

-- @@&&fc_set_value_var_nvl2. orachk_db_comp   '&&orachk_comp_column.' '&&orachk_db_file..comp'   '&&orachk_db_file.'
-- @@&&fc_set_value_var_nvl2. orachk_orig_comp '&&orachk_comp_column.' '&&orachk_orig_file..comp' '&&orachk_orig_file.'

@@&&fc_def_output_file. one_spool_html_file '&&orachk_file_pref._result.html'
@@&&fc_def_output_file. orachk_csv_file     '&&orachk_file_pref._result.csv'
DEF orachk_csv_field_sep = ','

-- Generate orachk_orig_file for compare
@@&&orachksum_fc_gen_orig_table.

-- Create Output for DB.
HOS touch &&orachk_db_file.
@@&&fc_spool_start.
@@&&orachk_skipif_unsupported.&&orachk_workdir./sql/&&orachk_sql_file. '&&orachk_db_file.' '&&orachk_file_pref.'
@@&&fc_spool_end.

-- Sort files
-- HOS sort &&orachk_db_file. > &&orachk_db_file..2
-- HOS mv &&orachk_db_file..2 &&orachk_db_file.

-- Gen compare files
@@&&orachk_exec_sh &&orachk_workdir./sh/gen_compare_file_csv.sh &&orachk_workdir. &&orachk_db_file.   &&orachk_db_comp.   &&orachk_comp_column.
@@&&orachk_exec_sh &&orachk_workdir./sh/gen_compare_file_csv.sh &&orachk_workdir. &&orachk_orig_file. &&orachk_orig_comp. &&orachk_comp_column.

-- Rem common comp files
@@&&fc_set_value_var_decode. orachk_skip_check '&&orachk_ver_pdbs.' '0' '' '&&fc_skip_script.'
@@&&orachk_skip_check.&&orachk_exec_sh &&orachk_workdir./sh/remove_cols_csv.sh &&orachk_workdir. &&orachk_db_comp.   &&orachk_db_comp.   &&orachk_tab_common_col.
@@&&orachk_skip_check.&&orachk_exec_sh &&orachk_workdir./sh/remove_cols_csv.sh &&orachk_workdir. &&orachk_orig_comp. &&orachk_orig_comp. &&orachk_tab_common_col.
UNDEF orachk_skip_check

-- Compare
@@&&orachk_exec_sh &&orachk_workdir./sh/csv_compare_files.sh &&orachk_db_comp. &&orachk_orig_comp. &&orachk_csv_file. &&orachk_db_file.
@@&&orachk_exec_sh &&orachk_workdir./sh/remove_comp_cols_csv.sh &&orachk_workdir. &&orachk_csv_file. &&orachk_csv_file..2 &&orachk_comp_column.
HOS mv &&orachk_csv_file..2 &&orachk_csv_file.
@@&&orachk_exec_sh &&orachk_workdir./sh/add_header_to_csv.sh &&orachk_workdir. &&orachk_csv_file. &&orachk_file_pref.
@@&&orachk_exec_sh &&sh_csv_to_html_table. &&orachk_csv_field_sep. &&orachk_csv_file. &&one_spool_html_file.
@@&&fc_add_tablefilter. &&one_spool_html_file.

-- Compute rows.
@@&&orachk_exec_sh &&orachk_workdir./sh/csv_num_rows.sh &&orachk_csv_file. &&orachk_db_file. &&orachk_csv_field_sep. &&orachk_tot_rows_db.
@@&&orachk_tot_rows_db.
HOS zip -mjT &&orachk_zip_file. &&orachk_tot_rows_db. >> &&moat369_log3.

BEGIN
  :sql_text := q'[
WITH t_src AS (
  SELECT 'Match - &&orachk_mch.' msg, &&orachk_mch. cnt FROM dual
  UNION ALL
  SELECT 'Difference - &&orachk_tdf.' msg, &&orachk_tdf. cnt FROM dual
),
t_res AS (
  SELECT msg, cnt, sum(cnt) over () total FROM t_src
)
SELECT msg, cnt,
       trim(to_char(round(cnt/decode(total,0,1,total),4)*100,'990D99')) percent,
       null dummy_01
FROM   t_res
where  total>0
UNION
SELECT 'No Lines Returned' msg, 1 cnt, to_char(100,'990D99') percent,
       null dummy_01
FROM   t_res
where  total=0
ORDER BY 3 DESC
]';
  :sql_text_display := q'[
Match      -> &&orachk_mch.
Difference -> &&orachk_tdf.
]';
END;
/

UNDEF orachk_mch
UNDEF orachk_nmc
UNDEF orachk_nfd
UNDEF orachk_tdf

DEF skip_html      = '--'
DEF skip_pch       = ''
DEF skip_html_file = ''
DEF skip_text_file = ''

DEF one_spool_text_file = '&&orachk_csv_file.'
DEF one_spool_text_file_type = 'csv'
DEF one_spool_text_file_rename = 'Y'
DEF one_spool_html_desc_table = 'Y'

DEF sql_show = 'N'

@@&&9a_pre_one.

--------------

DEF title = '&&orachk_subject. - Missing';
DEF main_table = '&&orachk_table_name.'

@@&&fc_def_output_file. one_spool_html_file '&&orachk_file_pref._result_miss.html'
@@&&fc_def_output_file. orachk_csv_file     '&&orachk_file_pref._result_miss.csv'
DEF orachk_csv_field_sep = ','

-- Compare
@@&&orachk_exec_sh &&orachk_workdir./sh/csv_compare_files.sh &&orachk_orig_comp. &&orachk_db_comp. &&orachk_csv_file. &&orachk_orig_file.
@@&&orachk_exec_sh &&orachk_workdir./sh/remove_comp_cols_csv.sh &&orachk_workdir. &&orachk_csv_file. &&orachk_csv_file..2 &&orachk_comp_column.
HOS mv &&orachk_csv_file..2 &&orachk_csv_file.
@@&&orachk_exec_sh &&orachk_workdir./sh/add_header_to_csv.sh &&orachk_workdir. &&orachk_csv_file. &&orachk_file_pref.
@@&&orachk_exec_sh &&sh_csv_to_html_table. &&orachk_csv_field_sep. &&orachk_csv_file. &&one_spool_html_file.
@@&&fc_add_tablefilter. &&one_spool_html_file.

-- Compute rows.
@@&&orachk_exec_sh &&orachk_workdir./sh/csv_num_rows.sh &&orachk_csv_file. &&orachk_orig_file. &&orachk_csv_field_sep. &&orachk_tot_rows_orig.
@@&&orachk_tot_rows_orig.
HOS zip -mjT &&orachk_zip_file. &&orachk_tot_rows_orig. >> &&moat369_log3.

BEGIN
  :sql_text := q'[
WITH t_src AS (
  SELECT 'Match - &&orachk_mch.' msg, &&orachk_mch. cnt FROM dual
  UNION ALL
  SELECT 'Difference - &&orachk_tdf.' msg, &&orachk_tdf. cnt FROM dual
),
t_res AS (
  SELECT msg, cnt, sum(cnt) over () total FROM t_src
)
SELECT msg, cnt,
       trim(to_char(round(cnt/decode(total,0,1,total),4)*100,'990D99')) percent,
       null dummy_01
FROM   t_res
where  total>0
UNION
SELECT 'No Lines Returned' msg, 1 cnt, to_char(100,'990D99') percent,
       null dummy_01
FROM   t_res
where  total=0
ORDER BY 3 DESC
]';
  :sql_text_display := q'[
Match      -> &&orachk_mch.
Difference -> &&orachk_tdf.
]';
END;
/

UNDEF orachk_mch
UNDEF orachk_nmc
UNDEF orachk_nfd
UNDEF orachk_tdf

DEF skip_html      = '--'
DEF skip_pch       = ''
DEF skip_html_file = ''
DEF skip_text_file = ''

DEF one_spool_text_file = '&&orachk_csv_file.'
DEF one_spool_text_file_type = 'csv'
DEF one_spool_text_file_rename = 'Y'
DEF one_spool_html_desc_table = 'Y'

DEF sql_show = 'N'

@@&&9a_pre_one.

----------------------------
----------------------------

HOS zip -mjT &&orachk_zip_file. &&orachk_db_file.   >> &&moat369_log3.
HOS zip -mjT &&orachk_zip_file. &&orachk_orig_file. >> &&moat369_log3.

HOS if [ -f &&orachk_db_comp. ];   then zip -mjT &&orachk_zip_file. &&orachk_db_comp.   >> &&moat369_log3.; fi
HOS if [ -f &&orachk_orig_comp. ]; then zip -mjT &&orachk_zip_file. &&orachk_orig_comp. >> &&moat369_log3.; fi

UNDEF orachk_table_name
UNDEF orachk_subject
UNDEF orachk_file_pref
UNDEF orachk_srczip_pref
UNDEF orachk_sql_file
UNDEF orachk_comp_column

UNDEF orachk_db_file
UNDEF orachk_orig_file

UNDEF orachk_tot_rows_db
UNDEF orachk_tot_rows_orig

UNDEF orachk_db_comp
UNDEF orachk_orig_comp

UNDEF orachk_csv_file orachk_csv_field_sep