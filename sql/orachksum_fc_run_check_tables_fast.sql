-- ----------------------------------------------------------------------------
-- Written by Rodrigo Jorge <http://www.dbarj.com.br/>
-- Last updated on: November/2017 by Rodrigo Jorge
-- ----------------------------------------------------------------------------

DEF title = '&&orachk_subject. - Extra';
DEF main_table = '&&orachk_table_owner..&&orachk_table_name.'

@@&&fc_def_output_file. orachk_db_file       '&&orachk_file_pref._db_out.csv'
@@&&fc_def_output_file. orachk_orig_file     '&&orachk_file_pref._orig.csv'

@@&&fc_def_output_file. orachk_tot_rows_db   '&&orachk_file_pref._csv_numrows_db.sql'
@@&&fc_def_output_file. orachk_tot_rows_orig '&&orachk_file_pref._csv_numrows_orig.sql'

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

-- Compare files.
HOS mv &&orachk_db_file.   &&orachk_path_tabfile1.
HOS mv &&orachk_orig_file. &&orachk_path_tabfile2.
@@&&orachk_workdir./sql/gen_sql_text_compare.sql '&&orachk_tab_numcols_csv.' '&&orachk_comp_column.' '&&orachk_tab_common_col.'
@@&&orachk_workdir./sql/create_csv_from_sql.sql '&&orachk_csv_file.' '&&orachk_tab_numcols_rep.'
HOS mv &&orachk_path_tabfile1. &&orachk_db_file.
HOS mv &&orachk_path_tabfile2. &&orachk_orig_file.

@@&&orachk_exec_sh &&orachk_workdir./sh/add_header_to_csv.sh &&orachk_workdir. &&orachk_csv_file. &&orachk_file_pref.
@@&&orachk_exec_sh &&sh_csv_to_html_table. &&orachk_csv_field_sep. &&orachk_csv_file. &&one_spool_html_file.
@@&&fc_add_tablefilter. &&one_spool_html_file.

-- Compute Rows
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
       trim(to_char(round(cnt/decode(total,0,1,total),4)*100,'990D99')) percent
FROM   t_res
where  total>0
UNION
SELECT 'No Lines Returned' msg, 1 cnt, to_char(100,'990D99') percent
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

DEF skip_html      = ''
DEF skip_pch       = ''
DEF skip_html_file = ''
DEF skip_text_file = ''

DEF one_spool_text_file = '&&orachk_csv_file.'
DEF one_spool_text_file_type = 'csv'
DEF one_spool_text_file_rename = 'Y'
DEF one_spool_html_desc_table = 'Y'
DEF one_spool_html_file_type = 'details'

--DEF sql_show = 'N'

@@&&9a_pre_one.

--------------

DEF title = '&&orachk_subject. - Missing';
DEF main_table = '&&orachk_table_owner..&&orachk_table_name.'

@@&&fc_def_output_file. one_spool_html_file '&&orachk_file_pref._result_miss.html'
@@&&fc_def_output_file. orachk_csv_file     '&&orachk_file_pref._result_miss.csv'
DEF orachk_csv_field_sep = ','

-- Compare files.
HOS cp &&orachk_orig_file. &&orachk_path_tabfile1.
HOS cp &&orachk_db_file.   &&orachk_path_tabfile2.
-- 2nd parameter must be quoted because 2nd can be null
@@&&orachk_workdir./sql/gen_sql_text_compare.sql '&&orachk_tab_numcols_csv.' '&&orachk_comp_column.' '&&orachk_tab_common_col.'
@@&&orachk_workdir./sql/create_csv_from_sql.sql '&&orachk_csv_file.' '&&orachk_tab_numcols_rep.'

@@&&orachk_exec_sh &&orachk_workdir./sh/add_header_to_csv.sh &&orachk_workdir. &&orachk_csv_file. &&orachk_file_pref.
@@&&orachk_exec_sh &&sh_csv_to_html_table. &&orachk_csv_field_sep. &&orachk_csv_file. &&one_spool_html_file.
@@&&fc_add_tablefilter. &&one_spool_html_file.

-- Compute Rows
@@&&orachk_exec_sh &&orachk_workdir./sh/csv_num_rows.sh &&orachk_csv_file. &&orachk_db_file. &&orachk_csv_field_sep. &&orachk_tot_rows_orig.
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
       trim(to_char(round(cnt/decode(total,0,1,total),4)*100,'990D99')) percent
FROM   t_res
where  total>0
UNION
SELECT 'No Lines Returned' msg, 1 cnt, to_char(100,'990D99') percent
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

DEF skip_html      = ''
DEF skip_pch       = ''
DEF skip_html_file = ''
DEF skip_text_file = ''

DEF one_spool_text_file = '&&orachk_csv_file.'
DEF one_spool_text_file_type = 'csv'
DEF one_spool_text_file_rename = 'Y'
DEF one_spool_html_desc_table = 'Y'
DEF one_spool_html_file_type = 'details'

--DEF sql_show = 'N'

@@&&9a_pre_one.

----------------------------
----------------------------

HOS zip -mjT &&orachk_zip_file. &&orachk_db_file.       >> &&moat369_log3.
HOS zip -mjT &&orachk_zip_file. &&orachk_orig_file.     >> &&moat369_log3.

UNDEF orachk_table_name
UNDEF orachk_table_owner
UNDEF orachk_subject
UNDEF orachk_file_pref
UNDEF orachk_srczip_pref
UNDEF orachk_sql_file
UNDEF orachk_comp_column

UNDEF orachk_db_file
UNDEF orachk_orig_file

UNDEF orachk_tot_rows_db
UNDEF orachk_tot_rows_orig

UNDEF orachk_tab_numcols_csv
UNDEF orachk_tab_numcols_rep
UNDEF orachk_tab_common_col
UNDEF orachk_tab_con_id_col

UNDEF orachk_csv_file orachk_csv_field_sep