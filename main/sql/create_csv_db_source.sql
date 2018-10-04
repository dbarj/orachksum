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

  TYPE v_array_skip IS TABLE OF VARCHAR2(200);

  ar_remove_lib_path v_array_skip := v_array_skip(
    --11g
    'SYS;DBMS_SUMADV_LIB;LIBRARY;',
    'ORDSYS;ORDIMLIBS;LIBRARY;',
    --12c
    'SYS;DBMS_SUMADV_LIB;LIBRARY;',
    'ORDSYS;ORDIMLIBS;LIBRARY;'
  );

  ar_remove_line_feed v_array_skip := v_array_skip(
    --11g
    'SYS;dbFWTrace;JAVA SOURCE;',
    'SYS;schedFileWatcherJava;JAVA SOURCE;',
    --12c
    'SYS;dbFWTrace;JAVA SOURCE;',
    'SYS;schedFileWatcherJava;JAVA SOURCE;'
  );

  ar_remove_hex_string v_array_skip := v_array_skip(
    --12c
    'SYS;WWV_FLOW_KEY;PACKAGE;'
  );

  VCODE CLOB;
  VNAME VARCHAR2(30);

  $IF DBMS_DB_VERSION.VER_LE_11
  $THEN
    CURSOR OBJS IS
      SELECT DISTINCT 
             OWNER,
             NAME,
             TYPE,
             NULL ORIGIN_CON_ID,
             NULL CON_ID,
             NULL CON_ID_CSV
      FROM   DBA_SOURCE
      WHERE  OWNER IN ('APEX_030200','CTXSYS','DBSNMP','DVF','DVSYS','EXFSYS','FLOWS_FILES','LBACSYS','MDSYS','OLAPSYS','ORACLE_OCM','ORDPLUGINS','ORDSYS','OUTLN','SYS','SYSMAN','SYSTEM','WMSYS','XDB')
      ORDER  BY 1,2,3,4;
    CURSOR LINS(X1 IN VARCHAR2, X2 IN VARCHAR2, X3 IN VARCHAR2, X4 IN NUMBER, X5 IN NUMBER) IS
      SELECT TEXT
      FROM   DBA_SOURCE
      WHERE  OWNER = X1
      AND    NAME  = X2
      AND    TYPE  = X3
      ORDER  BY LINE ASC;
  $ELSE
    CURSOR OBJS IS
      SELECT DISTINCT 
             OWNER,
             NAME,
             TYPE,
             ORIGIN_CON_ID,
             CON_ID,
             ORIGIN_CON_ID CON_ID_CSV -- Con ID to generate inside CSV file
      FROM   CDB_SOURCE
      WHERE  OWNER IN ('APEX_040200','CTXSYS','DBSNMP','DVF','DVSYS','FLOWS_FILES','GSMADMIN_INTERNAL','LBACSYS','MDSYS','OLAPSYS','ORACLE_OCM','ORDPLUGINS','ORDSYS','OUTLN','SYS','SYSTEM','WMSYS','XDB')
      AND    (ORIGIN_CON_ID=CON_ID -- FOR NON-CDBS OR CONNECTED TO ROOT DB
      OR      SYS_CONTEXT('USERENV', 'CON_ID') > 1) -- WHEN CONNECTED TO PDB
      ORDER  BY 1,2,3,4;
    CURSOR LINS(X1 IN VARCHAR2, X2 IN VARCHAR2, X3 IN VARCHAR2, X4 IN NUMBER, X5 IN NUMBER) IS
      SELECT TEXT
      FROM   CDB_SOURCE
      WHERE  OWNER         = X1
      AND    NAME          = X2
      AND    TYPE          = X3
      AND    ORIGIN_CON_ID = X4
      AND    CON_ID        = X5
      ORDER  BY LINE ASC;
  $END

  FUNCTION fc_remove_hex_string (V_STR_IN IN CLOB) RETURN CLOB IS
  begin
     RETURN REGEXP_REPLACE(V_STR_IN,'''([[:digit:]]|[A-F])*''',''''''); -- Remove random HEX code between single quotes
  end;
  FUNCTION fc_remove_lib_path (V_STR_IN IN CLOB) RETURN CLOB IS
  begin
     RETURN REGEXP_REPLACE(V_STR_IN,'''(.*)(/lib/[^/]*)''','''\2'''); -- Keep only the path after last "lib" folder
  end;
  FUNCTION fc_remove_line_feed (V_STR_IN IN CLOB) RETURN CLOB IS
  begin
     RETURN REGEXP_REPLACE(V_STR_IN,CHR(10),''); -- Remove line feed
  end;
  FUNCTION fc_remove_digits (V_STR_IN IN CLOB) RETURN CLOB IS
  begin
     RETURN REGEXP_REPLACE(V_STR_IN,'[[:digit:]]+',''); -- Remove digits
  end;
  FUNCTION fc_adapt_type (V_STR_IN IN VARCHAR2) RETURN VARCHAR2 IS
     V_FINAL_PART varchar2(30);
  begin
     -- Ira truncar o código até o início da parte de dígito em X casas e concatenar o restante, variando o tamanho de acordo com o tamanho da própria string final e qtd de dígitos.
     -- Ex: PERFORMED_PROCEDURE_STE123_T -> PERFORMED_PROCEDURE123_T (24) | PREDICATES_DEFINITIO499_COLL -> PREDICATES_DEFIN499_COLL (24) | MEDIA_STORAGE_SOP_INSTA88_T -> MEDIA_STORAGE_SOP_I88_T (23)
     IF LENGTH(V_STR_IN)>23 THEN
       V_FINAL_PART := REGEXP_SUBSTR(V_STR_IN,'[[:digit:]]+_(T|COLL)$');
       RETURN SUBSTR(V_STR_IN,1,LEAST(24-(3-LENGTH(SUBSTR(V_FINAL_PART,1,INSTR(V_FINAL_PART,'_')-1))),LENGTH(V_STR_IN))-LENGTH(V_FINAL_PART)) || V_FINAL_PART;
     ELSE
       RETURN V_STR_IN;
     END IF;
  end;
  FUNCTION fc_remove_type_name_from_code (V_STR_IN IN CLOB) RETURN CLOB IS
  begin
     RETURN REGEXP_REPLACE(V_STR_IN,'"([[:alpha:]]|_|-)+[[:digit:]]+_(T|COLL)"',''); -- Remove type name from code
  end;
  FUNCTION fc_remove_varwnum_from_code (V_STR_IN IN CLOB) RETURN CLOB IS
  begin
     RETURN REGEXP_REPLACE(V_STR_IN,'"[[:graph:]]*[[:digit:]]+[[:graph:]]*"','""'); -- Remove string with digits between ""
  end;
  FUNCTION fc_remove_strwnum_from_code (V_STR_IN IN CLOB) RETURN CLOB IS
  begin
     RETURN REGEXP_REPLACE(V_STR_IN,'''[[:graph:]]*[[:digit:]]+[[:graph:]]*''',''''''); -- Remove string with digits between ''
  end;
  -- [[:graph:]] should be replaced by [A-Z][a-z][0-9]_$+=#

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
    VCODE := ''; -- Zera a variável
    VNAME := I.NAME;

    FOR J IN LINS(I.OWNER, I.NAME, I.TYPE, I.ORIGIN_CON_ID, I.CON_ID)
    LOOP
      VCODE := VCODE || J.TEXT;
    END LOOP;

    -- BEGIN - Alter some codes
    IF I.OWNER || ';' || I.NAME || ';' || I.TYPE || ';' MEMBER OF ar_remove_lib_path THEN
      VCODE := fc_remove_lib_path(VCODE);
    END IF;
    IF I.OWNER || ';' || I.NAME || ';' || I.TYPE || ';' MEMBER OF ar_remove_line_feed THEN
      VCODE := fc_remove_line_feed(VCODE);
    END IF;
    IF I.OWNER || ';' || I.NAME || ';' || I.TYPE || ';' MEMBER OF ar_remove_hex_string THEN
      VCODE := fc_remove_hex_string(VCODE);
    END IF;

    IF I.OWNER IN ('MDSYS','XDB')  AND REGEXP_LIKE(I.NAME,'\$xd$') AND I.TYPE = 'TRIGGER' THEN
      VCODE := fc_remove_hex_string(VCODE);
    END IF;

    IF I.OWNER IN ('MDSYS','XDB')  AND REGEXP_LIKE(I.NAME,'_TAB\$xd$') AND I.TYPE = 'TRIGGER' THEN
      VNAME := fc_remove_digits(VNAME);
      VCODE := fc_remove_varwnum_from_code(VCODE);
      VCODE := fc_remove_strwnum_from_code(VCODE);
    END IF;

    -- Remove IDs from some TYPEs
    IF I.OWNER IN ('MDSYS','ORDSYS','SYS','XDB') AND REGEXP_LIKE(I.NAME,'^([[:alpha:]]|_|-)+[[:digit:]]+_(T|COLL)$') AND I.TYPE = 'TYPE' THEN
      VCODE := fc_remove_varwnum_from_code(VCODE);
      VNAME := fc_remove_digits(fc_adapt_type(VNAME));
    END IF;
    --IF I.OWNER = 'ORDSYS' AND REGEXP_LIKE(I.NAME,'^([[:alpha:]]|_|-)+[[:digit:]]+_(T|COLL)$') AND I.TYPE = 'TYPE' THEN
    --  VCODE := fc_remove_varwnum_from_code(VCODE);
    --END IF;
    IF I.OWNER IN ('SYS','DVSYS') AND REGEXP_LIKE(I.NAME,'^SYS_YOID([[:digit:]])*\$') AND I.TYPE = 'TYPE' THEN
      VCODE := fc_remove_varwnum_from_code(VCODE);
      VNAME := fc_remove_digits(VNAME);
    END IF;
    IF I.OWNER = 'SYS' AND REGEXP_LIKE(I.NAME,'^SYST.*==$') AND I.TYPE = 'TYPE' THEN
      VCODE := fc_remove_varwnum_from_code(VCODE);
      VNAME := REGEXP_REPLACE(VNAME,'^SYST.*==$','SYST==');
    END IF;

    IF VNAME = I.NAME THEN
      VNAME := '';
    END IF;
    -- END - Alter some codes
    DBMS_OUTPUT.PUT_LINE(
    QA(I.OWNER) || V_SEPARATOR ||
    QA(I.NAME) || V_SEPARATOR ||
    QA(VNAME) || V_SEPARATOR ||
    QA(I.TYPE) || V_SEPARATOR ||
    QA(I.CON_ID_CSV) || V_SEPARATOR ||
    QA(SYS.DBMS_CRYPTO.HASH(VCODE, SYS.DBMS_CRYPTO.HASH_SH1)));
  END LOOP;
END;
/

SPOOL OFF