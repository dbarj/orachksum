---------------- START PRETASKS 1 ----------------

-- ----------------------------------------------------------------------------
-- Written by Rodrigo Jorge <http://www.dbarj.com.br/>
-- Last updated on: Dec/2016 by Rodrigo Jorge
-- ----------------------------------------------------------------------------

@@&&fc_def_output_file. orachk_step_code_driver 'db_step_code_driver.sql'

-- Variables for orachksum
DEF orachk_file_pref      = 'db'
DEF orachk_srczip_pref    = 'db'
DEF orachk_comp_column    = ''
DEF orachk_comp_incl_root = 'Y'

@@&&fc_def_output_file. orachk_report_file  'report.txt'
@@&&fc_def_output_file. orachk_zip_file     'orachk.zip'

@@&&fc_def_output_file. orachk_orig_file     '&&orachk_file_pref._orig.csv'

-- Generate Orig Table for compare
@@&&orachksum_fc_gen_orig_table.

---------------- END PRETASKS 1 ----------------

@@&&fc_set_value_var_decode. main_table '&&is_ver_ge_12.' 'Y' 'CDB_SOURCE' 'DBA_SOURCE'
DEF orachk_subject      = 'SOURCE'
DEF orachk_file_pref    = 'source'
DEF orachk_sql_file     = 'create_csv_db_source.sql'
DEF orachk_comp_column  = '2,3'
@@&&orachksum_fc_run_check_hash.

--------------

@@&&fc_set_value_var_decode. main_table '&&is_ver_ge_12.' 'Y' 'CDB_VIEWS' 'DBA_VIEWS'
DEF orachk_subject      = 'VIEW'
DEF orachk_file_pref    = 'view'
DEF orachk_sql_file     = 'create_csv_db_view.sql'
DEF orachk_comp_column  = '2,3'
@@&&orachksum_fc_run_check_hash.

--------------

DEF title = 'Objects with Difference';
DEF totfiles = 200

HOS if [ $(cat &&orachk_version_file. | grep "ORA-20000" | wc -l) -eq 1 ]; then echo > &&orachk_step_code_driver.; fi
HOS if [ $(($(cat &&orachk_step_code_driver. | wc -l) / 9)) -gt &&totfiles. ]; then head -n $((9 * &&totfiles.)) &&orachk_step_code_driver. > &&orachk_step_code_driver..tmp; mv &&orachk_step_code_driver..tmp &&orachk_step_code_driver.; fi
--HOS if [ $(($(cat &&orachk_step_code_driver. | wc -l) / 9)) -gt &&totfiles. ]; then echo > &&orachk_step_code_driver.; fi
--HOS echo > &&orachk_step_code_driver.
@&&orachk_step_code_driver.
HOS zip -mjT &&orachk_zip_file. &&orachk_step_code_driver. >> &&moat369_log3.
UNDEF orachk_step_code_driver

--SET DEF OFF
BEGIN
  :sql_text := q'[
SELECT TEXT
FROM
  (SELECT 1 order1,
          0 order2,
          '<ul>' text
  FROM dual
  UNION
  SELECT 2 order1,
         row_number() over(order by object_type, object_owner, object_name) order2,
         '<li>' || 'Object: ' || object_owner || '.' || object_name || ' Type: ' || object_type || CHR(10) || ' <a href="' || substr(remarks,instr(remarks,'/',-1)+1) || '">code</a>' || CHR(10) || '</li>' text
  FROM  (
         select REPLACE(REPLACE(REPLACE(object_type, CHR(38),CHR(38) || 'amp;'),'>',CHR(38) || 'gt;'),'<',CHR(38) || 'lt;') object_type,
                REPLACE(REPLACE(REPLACE(object_owner,CHR(38),CHR(38) || 'amp;'),'>',CHR(38) || 'gt;'),'<',CHR(38) || 'lt;') object_owner,
                REPLACE(REPLACE(REPLACE(object_name, CHR(38),CHR(38) || 'amp;'),'>',CHR(38) || 'gt;'),'<',CHR(38) || 'lt;') object_name,
                REPLACE(REPLACE(REPLACE(remarks,     CHR(38),CHR(38) || 'amp;'),'>',CHR(38) || 'gt;'),'<',CHR(38) || 'lt;') remarks
         from plan_table
         WHERE statement_id = 'META_OBJCTS'
         )
  UNION
  SELECT 3 order1,
         0 order2,
         '</ul>' text
  FROM dual
  )
WHERE EXISTS (SELECT 1 FROM plan_table WHERE statement_id = 'META_OBJCTS')
ORDER BY ORDER1,
  ORDER2
]';
END;
/
--SET DEF ON

DEF skip_html_spool = ''
DEF skip_html = '--'
DEF row_num_dif = '-2'
DEF sql_show = 'N'
@@&&9a_pre_one.

-- Remove itens inserted on plan_table
rollback;

UNDEF totfiles

---------------- START POSTTASKS 1 ----------------

HOS zip -mjT &&orachk_zip_file. &&orachk_report_file.  >> &&moat369_log3.
HOS zip -mjT &&orachk_zip_file. &&orachk_orig_file.    >> &&moat369_log3.

@@&&fc_ren_output_file. orachk_zip_file
@@&&fc_encrypt_file. orachk_zip_file
HOS zip -mjT &&moat369_zip_filename. &&orachk_zip_file. >> &&moat369_log3.

-- Reset Variables for orachksum
UNDEF orachk_orig_file
UNDEF orachk_report_file
UNDEF orachk_zip_file
UNDEF orachk_comp_incl_root

---------------- END POSTTASKS 1 ----------------
