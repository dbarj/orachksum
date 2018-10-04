-- To run this code you need to provide:
-- Param1: Output CSV file name
-- Param2: Number of columns in the output CSV
-- SQL_TEXT bind variable with the SQL that will execute. SQL_TEXT must have at least "Param2" # columns and all named as C1, C2, C3, etc..
@@&&fc_set_term_off.
DEF orachk_sql_gen_out     = '&1.'
DEF orachk_sql_gen_numcols = '&2.'
UNDEF 1 2

@@&&fc_gen_temp_file. orachk_sql_gen_script '&&orachk_file_pref._sqlgen'

SET HEADING OFF
COL sql_text FOR A1000
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
PRO
PRO   CURSOR OBJ IS

PRINT sql_text

PRO   ;;
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
PRO   FOR I IN OBJ
PRO   LOOP
PRO     DBMS_OUTPUT.PUT_LINE(

select '     QA(I.C' || line || ')' || DECODE(line,total,'',' || V_SEPARATOR ||') || CHR(10)
from
(select rownum line, count(*) over () total from dual connect by level <= &&orachk_sql_gen_numcols.)
;

PRO     );;
PRO   END LOOP;;
PRO END;;
PRO /
PRO
PRO SPOOL OFF
SPOOL OFF

@&&orachk_sql_gen_script.

@@&&fc_spool_end.
SET HEADING ON

EXEC :sql_text := NULL;


HOS zip -mjT &&orachk_zip_file. &&orachk_sql_gen_script. >> &&moat369_log3.

UNDEF orachk_sql_gen_out
UNDEF orachk_sql_gen_numcols
UNDEF orachk_sql_gen_script