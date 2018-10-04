SET SERVEROUTPUT ON FORMAT WRAPPED
SET FEEDBACK OFF
SET TRIM ON
SET TRIMSPOOL ON

DECLARE
  V_ORA_VER_MAJOR NUMBER;
  V_ORA_VERSION   VARCHAR2(20);
BEGIN
  select substr(version,1,instr(version,'.',1,4)-1),substr(version,1,instr(version,'.',1,1)-1) into v_ora_version,v_ora_ver_major from sys.v$instance;
  IF v_ora_version IN ('12.1.0.1','12.1.0.2') THEN
    execute immediate 'alter session set exclude_seed_cdb_view=false';
  ELSIF v_ora_ver_major >= 12 THEN
    execute immediate 'alter session set "_exclude_seed_cdb_view"=false';
  END IF;
END;
/

spool &1
DECLARE
  V_ENCLOSURE VARCHAR2(1) := '"';
  V_SEPARATOR VARCHAR2(1) := ',';

  $IF DBMS_DB_VERSION.VER_LE_11
  $THEN 
    CURSOR OBJS IS
      SELECT OWNER,
             SYNONYM_NAME,
             TABLE_OWNER,
             TABLE_NAME,
             DB_LINK,
             NULL CON_ID_CSV
      FROM   dba_synonyms WHERE OWNER IN ('APEX_040200','APPQOSSYS','DBSNMP','DVSYS','FLOWS_FILES','PUBLIC','SI_INFORMTN_SCHEMA','SYS','SYSTEM')
      ORDER  BY 1,2,3,4;
  $ELSE
    CURSOR OBJS IS
      SELECT OWNER,
             SYNONYM_NAME,
             TABLE_OWNER,
             TABLE_NAME,
             DB_LINK,
             ORIGIN_CON_ID CON_ID_CSV -- Con ID to generate inside CSV file
      FROM   cdb_synonyms WHERE OWNER IN ('APEX_040200','APPQOSSYS','DBSNMP','DVSYS','FLOWS_FILES','PUBLIC','SI_INFORMTN_SCHEMA','SYS','SYSTEM')
      AND    (ORIGIN_CON_ID=CON_ID -- FOR NON-CDBS OR CONNECTED TO ROOT DB
      OR     SYS_CONTEXT('USERENV', 'CON_ID') > 1) -- WHEN CONNECTED TO PDB
      ORDER  BY 1,2,3,4;
  $END

  FUNCTION QA (IN_VALUE IN VARCHAR2) RETURN VARCHAR2 AS
    V_ENC VARCHAR2(1) := V_ENCLOSURE;
    V_SEP VARCHAR2(1) := V_SEPARATOR;
    OUT_VALUE   VARCHAR2(4000);
  BEGIN
    IF IN_VALUE IS NOT NULL THEN
      OUT_VALUE := REPLACE(REPLACE(IN_VALUE,CHR(13),' '),CHR(10),' ');
      IF OUT_VALUE LIKE '%' || V_ENC || '%' OR OUT_VALUE LIKE '%' || V_SEP || '%' THEN
        RETURN V_ENC || REPLACE(OUT_VALUE,V_ENC,V_ENC || V_ENC) || V_ENC;
      ELSE
        RETURN OUT_VALUE;
      END IF;
    ELSE
      RETURN NULL;
    END IF;
  END;

BEGIN
  DBMS_OUTPUT.ENABLE(NULL);

  FOR I IN OBJS
  LOOP
    DBMS_OUTPUT.PUT_LINE(
    QA(I.OWNER) || V_SEPARATOR ||
    QA(I.SYNONYM_NAME) || V_SEPARATOR ||
    QA(I.TABLE_OWNER) || V_SEPARATOR ||
    QA(I.TABLE_NAME) || V_SEPARATOR ||
    QA(I.DB_LINK) || V_SEPARATOR ||
    QA(I.CON_ID_CSV));
  END LOOP;
END;
/

SPOOL OFF