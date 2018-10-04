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

  VCODE CLOB;
  VNAME VARCHAR2(30);
  VSID  VARCHAR2(30) := 'ORACHKSUM_VIEW';

  TYPE v_array_skip IS TABLE OF VARCHAR2(200);

  ar_remove_qtobjno_string v_array_skip := v_array_skip(
    --12c
    'GSMADMIN_INTERNAL;AQ$CHANGE_LOG_QUEUE_TABLE;VIEW;',
    'SYS;AQ$ALERT_QT;VIEW;',
    'SYS;AQ$AQ$_MEM_MC;VIEW;',
    'SYS;AQ$AQ_PROP_TABLE;VIEW;',
    'SYS;AQ$SCHEDULER$_REMDB_JOBQTAB;VIEW;',
    'SYS;AQ$SCHEDULER_FILEWATCHER_QT;VIEW;',
    'SYS;AQ$SYS$SERVICE_METRICS_TAB;VIEW;',
    'WMSYS;AQ$WM$EVENT_QUEUE_TABLE;VIEW;',
    'SYS;AQ$SCHEDULER$_EVENT_QTAB;VIEW;'
  );

    CURSOR OBJS IS
      SELECT OBJECT_OWNER,
             OBJECT_NAME,
             OBJECT_TYPE,
             OBJECT_INSTANCE,
             OTHER_XML
      FROM   PLAN_TABLE
      WHERE  STATEMENT_ID = VSID-- and rownum < 1000;
      ORDER  BY 1,2;
   FUNCTION replaceClob
     ( srcClob IN CLOB,
       replaceStr IN varchar2,
       replaceWith IN varchar2 )
   RETURN CLOB
   IS
     l_buffer VARCHAR2 (32767);
     l_amount BINARY_INTEGER := 32767;
     l_pos INTEGER := 1;
     l_clob_len INTEGER;
	 newClob clob := EMPTY_CLOB;
   BEGIN
     -- initalize the new clob
     dbms_lob.CreateTemporary( newClob, TRUE );
	 l_clob_len := DBMS_LOB.getlength (srcClob);
     WHILE l_pos <= l_clob_len
     LOOP
         DBMS_LOB.READ (srcClob,l_amount,l_pos,l_buffer);
         IF l_buffer IS NOT NULL
         THEN
		   -- replace the text
		   l_buffer := regexp_replace(l_buffer,replaceStr,replaceWith);
		   -- write it to the new clob
	       DBMS_LOB.writeAppend(newClob, LENGTH(l_buffer), l_buffer);
         END IF;
         l_pos :=   l_pos + l_amount;
     END LOOP;
	 RETURN newClob;
   END;
   FUNCTION fc_remove_digits (V_STR_IN IN CLOB) RETURN CLOB IS
   begin
      RETURN REGEXP_REPLACE(V_STR_IN,'[[:digit:]]+',''); -- Remove digits
   end;
  FUNCTION fc_remove_qtobjno_string (V_STR_IN IN CLOB) RETURN CLOB IS
  begin
     RETURN REGEXP_REPLACE(V_STR_IN,'QTOBJNO=[[:digit:]]*','QTOBJNO='); -- Remove random HEX code between single quotes
  end;

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

  $IF DBMS_DB_VERSION.VER_LE_11
  $THEN
  INSERT INTO PLAN_TABLE (STATEMENT_ID, OBJECT_OWNER, OBJECT_NAME, OBJECT_TYPE, OBJECT_INSTANCE, OTHER_XML)
  SELECT VSID,
         OWNER,
         VIEW_NAME,
         'VIEW',
         NULL CON_ID_CSV, -- Con ID to generate inside CSV file
         TO_LOB(TEXT)
  FROM   DBA_VIEWS
  WHERE  OWNER IN ('APEX_040200','CTXSYS','DBSNMP','DVSYS','GSMADMIN_INTERNAL','LBACSYS','MDSYS','OLAPSYS','ORDDATA','ORDSYS','SYS','SYSTEM','WMSYS','XDB');

  $ELSE

  -- Take all the code for views in the current container.
  -- ORIGIN_CON_ID filter only applies when inside a PDB. In CDB the only ORIGIN_CON_ID is the own CDB, so it's redundant.
  INSERT INTO PLAN_TABLE (STATEMENT_ID, OBJECT_OWNER, OBJECT_NAME, OBJECT_TYPE, OBJECT_INSTANCE, OTHER_XML)
  SELECT VSID,
         OWNER,
         VIEW_NAME,
         'VIEW',
         ORIGIN_CON_ID CON_ID_CSV, -- Con ID to generate inside CSV file
         TO_LOB(TEXT)
  FROM   DBA_VIEWS
  WHERE  OWNER IN ('APEX_040200','CTXSYS','DBSNMP','DVSYS','GSMADMIN_INTERNAL','LBACSYS','MDSYS','OLAPSYS','ORDDATA','ORDSYS','SYS','SYSTEM','WMSYS','XDB')
  AND    ORIGIN_CON_ID = SYS_CONTEXT('USERENV','CON_ID');

  -- Take all the code for views in the other containers when in the PDB.
  -- ORIGIN_CON_ID filter only applies when inside a PDB. In CDB the only ORIGIN_CON_ID is the own CDB, so it's redundant.
  INSERT INTO PLAN_TABLE (STATEMENT_ID, OBJECT_OWNER, OBJECT_NAME, OBJECT_TYPE, OBJECT_INSTANCE, OTHER_XML)
  SELECT VSID,
         OWNER,
         VIEW_NAME,
         'VIEW',
         ORIGIN_CON_ID CON_ID_CSV, -- Con ID to generate inside CSV file
         TEXT_VC
  FROM   DBA_VIEWS
  WHERE  OWNER IN ('APEX_040200','CTXSYS','DBSNMP','DVSYS','GSMADMIN_INTERNAL','LBACSYS','MDSYS','OLAPSYS','ORDDATA','ORDSYS','SYS','SYSTEM','WMSYS','XDB')
  AND    ORIGIN_CON_ID <> SYS_CONTEXT('USERENV','CON_ID');

  -- Take all the code for views in the other containers when in the CDB.
  -- Only works if current container is CDB (CON_ID filter). Most of the views (~20) get truncated (4000 chars limit). Need to fix.
  INSERT INTO PLAN_TABLE (STATEMENT_ID, OBJECT_OWNER, OBJECT_NAME, OBJECT_TYPE, OBJECT_INSTANCE, OTHER_XML)
  SELECT VSID,
         OWNER,
         VIEW_NAME,
         'VIEW',
         ORIGIN_CON_ID CON_ID_CSV, -- Con ID to generate inside CSV file
         TEXT_VC
  FROM   CDB_VIEWS
  WHERE  OWNER IN ('APEX_040200','CTXSYS','DBSNMP','DVSYS','GSMADMIN_INTERNAL','LBACSYS','MDSYS','OLAPSYS','ORDDATA','ORDSYS','SYS','SYSTEM','WMSYS','XDB')
  AND    CON_ID <> SYS_CONTEXT('USERENV','CON_ID')
  AND    ORIGIN_CON_ID = CON_ID;
  $END
  FOR I IN OBJS
  LOOP
    VCODE := UPPER(I.OTHER_XML);
    VCODE := replaceClob(VCODE,'[[:space:]]*',''); -- Remove all space characters
    VCODE := replaceClob(VCODE,'"',''); -- Remove all quotes
    VNAME := '';
    -- BEGIN - Alter some codes
    IF I.OBJECT_OWNER || ';' || I.OBJECT_NAME || ';' || I.OBJECT_TYPE || ';' MEMBER OF ar_remove_qtobjno_string THEN
      VCODE := fc_remove_qtobjno_string(VCODE);
    END IF;
    -- Remove IDs from some TYPEs
    IF I.OBJECT_OWNER IN ('SYS') AND REGEXP_LIKE(I.OBJECT_NAME,'^QT([[:digit:]])*_BUFFER$') AND I.OBJECT_TYPE = 'VIEW' THEN
      VCODE := fc_remove_digits(VCODE);
      VNAME := fc_remove_digits(I.OBJECT_NAME);
    END IF;
    -- END - Alter some codes
    DBMS_OUTPUT.PUT_LINE(
    QA(I.OBJECT_OWNER) || V_SEPARATOR ||
    QA(I.OBJECT_NAME) || V_SEPARATOR ||
    QA(VNAME) || V_SEPARATOR ||
    QA(I.OBJECT_TYPE) || V_SEPARATOR ||
    QA(I.OBJECT_INSTANCE) || V_SEPARATOR ||
    QA(SYS.DBMS_CRYPTO.HASH(VCODE, SYS.DBMS_CRYPTO.HASH_SH1)));
  END LOOP;
  ROLLBACK;
END;
/

SPOOL OFF