DEF orachk_sql_gen_out = '&1.'
UNDEF 1

@@&&fc_gen_temp_file.   orachk_sql_gen_script '&&orachk_file_pref._sqlgen'
@@&&fc_def_output_file. orachk_sql_gen_cols   '&&orachk_file_pref._sqlgen_cols.txt'

-- Generate CSV to compare.
@@&&orachk_exec_sh &&orachk_workdir./sh/gen_table_header.sh &&orachk_workdir. &&orachk_file_pref. &&orachk_sql_gen_cols.
@@&&orachk_sql_gen_cols.
HOS rm -f &&orachk_sql_gen_cols.

SET HEADING OFF
@@&&fc_spool_start.

SPOOL &&orachk_sql_gen_script.
PRO SET SERVEROUTPUT ON FORMAT WRAPPED
PRO SET FEEDBACK OFF
PRO SET TRIM ON
PRO SET TRIMSPOOL ON
PRO
PRO spool &&orachk_sql_gen_out.
PRO DECLARE
PRO   V_ORA_VER_MAJOR NUMBER;;
PRO   V_ORA_VERSION VARCHAR2(20);;
PRO   V_ENCLOSURE VARCHAR2(1) := '"';;
PRO   V_SEPARATOR VARCHAR2(1) := ',';;
PRO
PRO   CURSOR OBJ IS
PRO     SELECT

WITH t ( value, start_pos, end_pos ) AS
  ( SELECT value, 1, INSTR( value, ',' ) FROM (SELECT :orachk_cols value FROM DUAL)
  UNION ALL
  SELECT value,
    end_pos                    + 1,
    INSTR( value, ',', end_pos + 1 )
  FROM t
  WHERE end_pos > 0
  )
select listagg(nvl(c2.column_name,'NULL') || ' AS ' || c1.column_name,', ' || CHR(10)) within group(order by c1.column_id)
from   (SELECT SUBSTR( value, start_pos, DECODE( end_pos, 0, LENGTH( value ) + 1, end_pos ) - start_pos ) AS column_name,
         rank() over (order by start_pos) AS column_id
       FROM t) c1, dba_tab_columns c2
where  c2.table_name (+) = '&&orachk_table_name.'
and    c2.owner(+) = 'SYS'
and    c1.column_name = c2.column_name (+);

PRO     FROM   &&orachk_table_name.
PRO     ORDER  BY 1,2,3,4;;
PRO
PRO   FUNCTION QA (IN_VALUE IN VARCHAR2) RETURN VARCHAR2 AS
PRO     V_ENC VARCHAR2(1) := V_ENCLOSURE;;
PRO     V_SEP VARCHAR2(1) := V_SEPARATOR;;
PRO     OUT_VALUE   VARCHAR2(4000);;
PRO   BEGIN
PRO     IF IN_VALUE IS NOT NULL THEN
PRO       OUT_VALUE := REPLACE(REPLACE(IN_VALUE,CHR(13),' '),CHR(10),' ');;
PRO       IF OUT_VALUE LIKE '%' || V_ENC || '%' OR OUT_VALUE LIKE '%' || V_SEP || '%' THEN
PRO         RETURN V_ENC || REPLACE(OUT_VALUE,V_ENC,V_ENC || V_ENC) || V_ENC;;
PRO       ELSE
PRO         RETURN OUT_VALUE;;
PRO       END IF;;
PRO     ELSE
PRO       RETURN NULL;;
PRO     END IF;;
PRO   END;;
PRO
PRO BEGIN
PRO   DBMS_OUTPUT.ENABLE(NULL);;
PRO   select substr(version,1,instr(version,'.',1,4)-1),substr(version,1,instr(version,'.',1,1)-1) into v_ora_version,v_ora_ver_major from sys.v$instance;;
PRO   IF v_ora_version IN ('12.1.0.1','12.1.0.2') THEN
PRO     execute immediate 'alter session set exclude_seed_cdb_view=false';;
PRO   ELSIF v_ora_ver_major >= 12 THEN
PRO     execute immediate 'alter session set "_exclude_seed_cdb_view"=false';;
PRO   END IF;;
PRO
PRO   IF v_ora_version IN ('11.2.0.4','12.1.0.1','12.1.0.2','12.2.0.1','18.0.0.0') THEN
PRO     FOR I IN OBJ
PRO     LOOP
PRO       DBMS_OUTPUT.PUT_LINE(

select '       QA(I.' || REPLACE(:orachk_cols,',',') || V_SEPARATOR ||' || CHR(10) || '     QA(I.') || ')'
from   dual;

PRO       );;
PRO     END LOOP;;
PRO   END IF;;
PRO END;;
PRO /
PRO
PRO SPOOL OFF
SPOOL OFF

@&&orachk_sql_gen_script.

SET HEADING ON
@@&&fc_spool_end.

HOS zip -mjT &&orachk_zip_file. &&orachk_sql_gen_script. >> &&moat369_log3.

VAR orachk_cols VARCHAR2(4000)

UNDEF orachk_sql_gen_out
UNDEF orachk_sql_gen_cols
UNDEF orachk_sql_gen_script