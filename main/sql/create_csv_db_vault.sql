DEF orachk_sql_gen_out = '&1.'
UNDEF 1

@@&&fc_gen_temp_file.   orachk_sql_gen_script '&&orachk_file_pref._sqlgen'
@@&&fc_def_output_file. orachk_sql_gen_cols   '&&orachk_file_pref._sqlgen_cols.txt'

-- Generate CSV to compare.
@@&&orachk_exec_sh &&orachk_workdir./sh/gen_table_header.sh &&orachk_workdir. &&orachk_file_pref. &&orachk_sql_gen_cols.
@@&&orachk_sql_gen_cols.

HOS zip -mjT &&orachk_zip_file. &&orachk_sql_gen_cols. >> &&moat369_log3.
-- HOS rm -f &&orachk_sql_gen_cols.

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
PRO   V_ENCLOSURE VARCHAR2(1) := '"';;
PRO   V_SEPARATOR VARCHAR2(1) := ',';;
PRO   V_SQL CLOB;;
PRO
PRO   FUNCTION QA (IN_VALUE IN VARCHAR2) RETURN VARCHAR2 AS
PRO     OUT_VALUE   VARCHAR2(4000);;
PRO   BEGIN
PRO     IF IN_VALUE IS NOT NULL THEN
PRO       OUT_VALUE := REPLACE(REPLACE(IN_VALUE,CHR(13),' '),CHR(10),' ');;
PRO       IF OUT_VALUE LIKE '%' || V_ENCLOSURE || '%' OR OUT_VALUE LIKE '%' || V_SEPARATOR || '%' THEN
PRO         RETURN V_ENCLOSURE || REPLACE(OUT_VALUE,V_ENCLOSURE,V_ENCLOSURE || V_ENCLOSURE) || V_ENCLOSURE;;
PRO       ELSE
PRO         RETURN OUT_VALUE;;
PRO       END IF;;
PRO     ELSE
PRO       RETURN NULL;;
PRO     END IF;;
PRO   END;;
PRO
PRO   PROCEDURE PRINT_QRY (P_QUERY IN CLOB) AS
PRO     L_THECURSOR INTEGER DEFAULT DBMS_SQL.OPEN_CURSOR;;
PRO     L_COLUMNVALUE VARCHAR2(2000);;
PRO     L_STATUS INTEGER;;
PRO     L_COLCNT NUMBER DEFAULT 0;;
PRO     L_SEP    VARCHAR2(1);;
PRO   BEGIN
PRO   
PRO     DBMS_OUTPUT.ENABLE(NULL);;
PRO   
PRO     DBMS_SQL.PARSE( L_THECURSOR, P_QUERY, DBMS_SQL.NATIVE );;
PRO   
PRO     FOR I IN 1 .. 255
PRO     LOOP
PRO       BEGIN
PRO         DBMS_SQL.DEFINE_COLUMN( L_THECURSOR, I, L_COLUMNVALUE, 2000 );;
PRO         L_COLCNT := I;;
PRO         EXCEPTION
PRO           WHEN OTHERS THEN
PRO           IF ( SQLCODE = -1007 ) THEN EXIT;;
PRO           ELSE
PRO           RAISE;;
PRO         END IF;;
PRO       END;;
PRO     END LOOP;;
PRO     
PRO     DBMS_SQL.DEFINE_COLUMN( L_THECURSOR, 1, L_COLUMNVALUE, 2000 );;
PRO     
PRO     L_STATUS := DBMS_SQL.EXECUTE(L_THECURSOR);;
PRO     
PRO     LOOP
PRO       EXIT WHEN ( DBMS_SQL.FETCH_ROWS(L_THECURSOR) <= 0 );;
PRO       L_SEP := '';;
PRO       FOR I IN 1 .. L_COLCNT
PRO       LOOP
PRO         DBMS_SQL.COLUMN_VALUE( L_THECURSOR, I, L_COLUMNVALUE );;
PRO         DBMS_OUTPUT.PUT( L_SEP || QA(L_COLUMNVALUE) );;
PRO         L_SEP := V_SEPARATOR;;
PRO       END LOOP;;
PRO       DBMS_OUTPUT.PUT_LINE('');;
PRO     END LOOP;;
PRO     DBMS_SQL.CLOSE_CURSOR(L_THECURSOR);;
PRO   
PRO   END;;
PRO
PRO BEGIN
PRO   DBMS_OUTPUT.ENABLE(NULL);;

PRO   V_SQL := q'[
PRO     SELECT

WITH t ( value, start_pos, end_pos ) AS
  ( SELECT value, 1, INSTR( value, ',' ) FROM (SELECT :orachk_cols value FROM DUAL)
  UNION ALL
  SELECT value,
    end_pos                    + 1,
    INSTR( value, ',', end_pos + 1 )
  FROM t
  WHERE end_pos > 0
  ),
oraver as (select substr(version,1,instr(version,'.',1,4)-1) v_ora_version from sys.v$instance)
-- For Vault Tables, will be always DBA_ prefixed tables (never CDB_), so CON_ID column will not exists. As the method is through CONTAINERS clause, forcelly include it:
select listagg(decode(c1.column_name,'CON_ID',decode(v_ora_version,'11.2.0.4','NULL','CON_ID'),nvl(c2.column_name,'NULL')) || ' AS ' || c1.column_name,', ' || CHR(10)) within group(order by c1.column_id)
from   (SELECT SUBSTR( value, start_pos, DECODE( end_pos, 0, LENGTH( value ) + 1, end_pos ) - start_pos ) AS column_name,
         rank() over (order by start_pos) AS column_id
       FROM t) c1, dba_tab_columns c2, oraver c3
where  c2.table_name (+) = '&&orachk_table_name.'
and    c2.owner(+) = 'DVSYS'
and    c1.column_name = c2.column_name (+);

SELECT '     FROM   ' || DECODE(v_ora_version,'11.2.0.4','DVSYS.&&orachk_table_name.','12.1.0.1','CDB$VIEW("DVSYS"."&&orachk_table_name.")','CONTAINERS(DVSYS.&&orachk_table_name.)') STR
FROM (select substr(version,1,instr(version,'.',1,4)-1) v_ora_version from sys.v$instance);

PRO     ORDER  BY 1,2,3,4
PRO   ]';;

PRO   PRINT_QRY(V_SQL);;
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