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
  V_SQL CLOB;

  V_PERMS_TYPE VARCHAR2(30) := UPPER('&2');

  VNAME VARCHAR2(30);
  V_ORA_VERSION VARCHAR2(20);
  V_ORA_VER_MAJOR NUMBER;
  V_IS_11204 BOOLEAN;

  TYPE OBJ_T IS REF CURSOR;
  OBJ OBJ_T;

  TYPE I_T IS RECORD (
    GRANTEE     DBA_TAB_PRIVS.GRANTEE%TYPE,
    OWNER       DBA_TAB_PRIVS.OWNER%TYPE,
    TABLE_NAME  DBA_TAB_PRIVS.TABLE_NAME%TYPE,
    GRANTOR     DBA_TAB_PRIVS.GRANTOR%TYPE,
    PRIVILEGE   DBA_TAB_PRIVS.PRIVILEGE%TYPE,
    GRANTABLE   DBA_TAB_PRIVS.GRANTABLE%TYPE,
    HIERARCHY   DBA_TAB_PRIVS.HIERARCHY%TYPE,
    TYPE        VARCHAR2(24),
    INHERITED   VARCHAR2(3),
    COMMON      VARCHAR2(3),
    CON_ID      NUMBER
  );

  I I_T;

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

  FUNCTION fc_remove_digits (V_STR_IN IN VARCHAR2) RETURN VARCHAR2 IS
  begin
     RETURN REGEXP_REPLACE(V_STR_IN,'[[:digit:]]+',''); -- Remove digits
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
  SELECT SUBSTR(VERSION,1,INSTR(VERSION,'.',1,4)-1),SUBSTR(VERSION,1,INSTR(VERSION,'.',1,1)-1) INTO V_ORA_VERSION,V_ORA_VER_MAJOR FROM SYS.V$INSTANCE;
  IF ( V_ORA_VERSION = '11.2.0.4') THEN
    V_IS_11204 := TRUE;
  ELSE
    V_IS_11204 := FALSE;
  END IF;

  IF v_ora_version = '11.2.0.4' THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.OWNER,
             P.TABLE_NAME,
             P.GRANTOR,
             P.PRIVILEGE,
             P.GRANTABLE,
             P.HIERARCHY,
             NULL TYPE,
             NULL INHERITED,
             NULL COMMON,
             NULL CON_ID
      FROM   DBA_TAB_PRIVS P
      WHERE  ( P.OWNER IN &&default_user_list_11g_1. OR P.OWNER IN &&default_user_list_11g_2. )
      ORDER  BY 1,2,3,4]';
  ELSIF v_ora_version in ('12.1.0.1','12.1.0.2') THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.OWNER,
             P.TABLE_NAME,
             P.GRANTOR,
             P.PRIVILEGE,
             P.GRANTABLE,
             P.HIERARCHY,
             P.TYPE,
             NULL INHERITED,
             P.COMMON,
             P.CON_ID
      FROM   CDB_TAB_PRIVS P, CDB_USERS U
      WHERE  P.OWNER = U.USERNAME
      AND    P.CON_ID = U.CON_ID
      AND    U.ORACLE_MAINTAINED = 'Y'
      ORDER  BY 1,2,3,4]';
  ELSIF v_ora_ver_major >= 12 THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.OWNER,
             P.TABLE_NAME,
             P.GRANTOR,
             P.PRIVILEGE,
             P.GRANTABLE,
             P.HIERARCHY,
             P.TYPE,
             P.INHERITED,
             P.COMMON,
             P.CON_ID
      FROM   CDB_TAB_PRIVS P, CDB_USERS U
      WHERE  P.OWNER = U.USERNAME
      AND    P.CON_ID = U.CON_ID
      AND    U.ORACLE_MAINTAINED = 'Y'
      ORDER  BY 1,2,3,4]';
  ELSE
    V_SQL := q'[
      SELECT NULL GRANTEE,
             NULL OWNER,
             NULL TABLE_NAME,
             NULL GRANTOR,
             NULL PRIVILEGE,
             NULL GRANTABLE,
             NULL HIERARCHY,
             NULL TYPE,
             NULL INHERITED,
             NULL COMMON,
             NULL CON_ID
      FROM   DUAL
      WHERE  1=2]';
  END IF;

  OPEN OBJ FOR V_SQL;  

  DBMS_OUTPUT.ENABLE(NULL);

  CASE V_PERMS_TYPE
   WHEN 'PRIVS_TAB' THEN
    LOOP
      FETCH OBJ INTO I;
      EXIT WHEN OBJ%NOTFOUND;
      VNAME := '';
      IF I.OWNER IN ('MDSYS','ORDSYS','SYS','XDB') AND REGEXP_LIKE(I.TABLE_NAME,'^([[:alpha:]]|_|-)+[[:digit:]]+_(T|COLL)$') AND (I.TYPE = 'TYPE' OR V_IS_11204) AND I.GRANTEE IN ('XDB','PUBLIC') THEN
        VNAME := fc_remove_digits(fc_adapt_type(I.TABLE_NAME));
      ELSIF I.OWNER = 'XDB' AND REGEXP_LIKE(I.TABLE_NAME,'^X\$PT.*') AND (I.TYPE = 'TABLE' OR V_IS_11204) AND I.GRANTEE IN ('DBA','SYSTEM') THEN
        VNAME := REGEXP_REPLACE(I.TABLE_NAME,'^X\$PT.*','X$PT');
      ELSIF I.OWNER = 'SYS' AND REGEXP_LIKE(I.TABLE_NAME,'^QT([[:digit:]])+_BUFFER$') AND (I.TYPE = 'VIEW' OR V_IS_11204) THEN
        VNAME := REGEXP_REPLACE(I.TABLE_NAME,'^QT([[:digit:]])+_BUFFER$','QT_BUFFER');
      ELSIF I.OWNER = 'SYS' AND REGEXP_LIKE(I.TABLE_NAME,'^SYST.*==$') AND (I.TYPE = 'TYPE' OR V_IS_11204) AND I.GRANTEE = 'PUBLIC' THEN
        VNAME := REGEXP_REPLACE(I.TABLE_NAME,'^SYST.*==$','SYST==');
      ELSIF I.OWNER = 'XDB' AND REGEXP_LIKE(I.TABLE_NAME,'^SYS_NT') AND (I.TYPE = 'TABLE' OR V_IS_11204) AND I.GRANTEE = 'SELECT_CATALOG_ROLE' THEN
        VNAME := REGEXP_REPLACE(I.TABLE_NAME,'^SYS_NT.*','SYS_NT');
      ELSIF I.OWNER = 'XDB' AND REGEXP_LIKE(I.TABLE_NAME,'^X\$(NM|PT|QN)') AND (I.TYPE = 'TABLE' OR V_IS_11204) AND I.GRANTEE = 'SELECT_CATALOG_ROLE' THEN
        VNAME := REGEXP_REPLACE(I.TABLE_NAME,'^(X\$(NM|PT|QN)).*','\1');
      END IF;
      DBMS_OUTPUT.PUT_LINE(
      QA(I.GRANTEE) || V_SEPARATOR ||
      QA(I.OWNER) || V_SEPARATOR ||
      QA(I.TABLE_NAME) || V_SEPARATOR ||
      QA(I.GRANTOR) || V_SEPARATOR ||
      QA(I.PRIVILEGE) || V_SEPARATOR ||
      QA(I.GRANTABLE) || V_SEPARATOR ||
      QA(I.HIERARCHY) || V_SEPARATOR ||
      QA(I.TYPE) || V_SEPARATOR ||
      QA(VNAME) || V_SEPARATOR ||
      QA(I.INHERITED) || V_SEPARATOR ||
      QA(I.COMMON) || V_SEPARATOR ||
      QA(I.CON_ID));
    END LOOP;
   ELSE
    NULL;
  END CASE;

  CLOSE OBJ;

END;
/

DECLARE
  V_ENCLOSURE VARCHAR2(1) := '"';
  V_SEPARATOR VARCHAR2(1) := ',';
  V_ORA_VER_MAJOR NUMBER;
  V_ORA_VERSION VARCHAR2(20);
  V_SQL CLOB;

  V_PERMS_TYPE VARCHAR2(30) := UPPER('&2');

  TYPE OBJ_T IS REF CURSOR;
  OBJ OBJ_T;

  TYPE I_T IS RECORD (
    GRANTEE     DBA_TAB_PRIVS.GRANTEE%TYPE,
    OWNER       DBA_TAB_PRIVS.OWNER%TYPE,
    TABLE_NAME  DBA_TAB_PRIVS.TABLE_NAME%TYPE,
    GRANTOR     DBA_TAB_PRIVS.GRANTOR%TYPE,
    PRIVILEGE   DBA_TAB_PRIVS.PRIVILEGE%TYPE,
    GRANTABLE   DBA_TAB_PRIVS.GRANTABLE%TYPE,
    HIERARCHY   DBA_TAB_PRIVS.HIERARCHY%TYPE,
    TYPE        VARCHAR2(24),
    INHERITED   VARCHAR2(3),
    COMMON      VARCHAR2(3),
    CON_ID      NUMBER
  );

  I I_T;

  FUNCTION QA (IN_VALUE IN VARCHAR2) RETURN VARCHAR2 AS
    V_ENCLOSURE VARCHAR2(1) := '"';
    V_SEPARATOR VARCHAR2(1) := ',';
    OUT_VALUE   VARCHAR2(4000);
  BEGIN
    IF IN_VALUE IS NOT NULL THEN
      OUT_VALUE := REPLACE(REPLACE(IN_VALUE,CHR(13),' '),CHR(10),' ');
      IF OUT_VALUE LIKE '%' || V_ENCLOSURE || '%' OR OUT_VALUE LIKE '%' || V_SEPARATOR || '%' THEN
        RETURN V_ENCLOSURE || REPLACE(OUT_VALUE,V_ENCLOSURE,V_ENCLOSURE || V_ENCLOSURE) || V_ENCLOSURE;
      ELSE
        RETURN OUT_VALUE;
      END IF;
    ELSE
      RETURN NULL;
    END IF;
  END;

BEGIN
  DBMS_OUTPUT.ENABLE(NULL);

  SELECT SUBSTR(VERSION,1,INSTR(VERSION,'.',1,4)-1),SUBSTR(VERSION,1,INSTR(VERSION,'.',1,1)-1) INTO V_ORA_VERSION,V_ORA_VER_MAJOR FROM SYS.V$INSTANCE;
  IF v_ora_version = '11.2.0.4' THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.OWNER,
             P.TABLE_NAME,
             P.GRANTOR,
             P.PRIVILEGE,
             P.GRANTABLE,
             P.HIERARCHY,
             NULL TYPE,
             NULL INHERITED,
             NULL COMMON,
             NULL CON_ID
      FROM   DBA_TAB_PRIVS P
      WHERE  NOT ( P.OWNER IN &&default_user_list_11g_1. OR P.OWNER IN &&default_user_list_11g_2. )
      ORDER  BY 1,2,3,4]';
  ELSIF v_ora_version in ('12.1.0.1','12.1.0.2') THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.OWNER,
             P.TABLE_NAME,
             P.GRANTOR,
             P.PRIVILEGE,
             P.GRANTABLE,
             P.HIERARCHY,
             P.TYPE,
             NULL INHERITED,
             P.COMMON,
             P.CON_ID
      FROM   CDB_TAB_PRIVS P, CDB_USERS U
      WHERE  P.OWNER = U.USERNAME
      AND    P.CON_ID = U.CON_ID
      AND    NOT (U.ORACLE_MAINTAINED = 'Y')
      ORDER  BY 1,2,3,4]';
  ELSIF v_ora_ver_major >= 12 THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.OWNER,
             P.TABLE_NAME,
             P.GRANTOR,
             P.PRIVILEGE,
             P.GRANTABLE,
             P.HIERARCHY,
             P.TYPE,
             P.INHERITED,
             P.COMMON,
             P.CON_ID
      FROM   CDB_TAB_PRIVS P, CDB_USERS U
      WHERE  P.OWNER = U.USERNAME
      AND    P.CON_ID = U.CON_ID
      AND    NOT (U.ORACLE_MAINTAINED = 'Y')
      ORDER  BY 1,2,3,4]';
  ELSE
    V_SQL := q'[
      SELECT NULL GRANTEE,
             NULL OWNER,
             NULL TABLE_NAME,
             NULL GRANTOR,
             NULL PRIVILEGE,
             NULL GRANTABLE,
             NULL HIERARCHY,
             NULL TYPE,
             NULL INHERITED,
             NULL COMMON,
             NULL CON_ID
      FROM   DUAL
      WHERE  1=2]';
  END IF;

  OPEN OBJ FOR V_SQL;  

  CASE V_PERMS_TYPE
   WHEN 'PRIVS_TAB_OTHERS' THEN
    LOOP
      FETCH OBJ INTO I;
      EXIT WHEN OBJ%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(
      QA(I.GRANTEE) || V_SEPARATOR ||
      QA(I.OWNER) || V_SEPARATOR ||
      QA(I.TABLE_NAME) || V_SEPARATOR ||
      QA(I.GRANTOR) || V_SEPARATOR ||
      QA(I.PRIVILEGE) || V_SEPARATOR ||
      QA(I.GRANTABLE) || V_SEPARATOR ||
      QA(I.HIERARCHY) || V_SEPARATOR ||
      QA(I.TYPE) || V_SEPARATOR ||
      QA(I.INHERITED) || V_SEPARATOR ||
      QA(I.COMMON) || V_SEPARATOR ||
      QA(I.CON_ID));
    END LOOP;
   ELSE
    NULL;
  END CASE;
  CLOSE OBJ;

END;
/

DECLARE
  V_ENCLOSURE VARCHAR2(1) := '"';
  V_SEPARATOR VARCHAR2(1) := ',';
  V_ORA_VER_MAJOR NUMBER;
  V_ORA_VERSION VARCHAR2(20);
  V_SQL CLOB;

  V_PERMS_TYPE VARCHAR2(30) := UPPER('&2');

  TYPE OBJ_T IS REF CURSOR;
  OBJ OBJ_T;

  TYPE I_T IS RECORD (
    GRANTEE         DBA_ROLE_PRIVS.GRANTEE%TYPE,
    GRANTED_ROLE    DBA_ROLE_PRIVS.GRANTED_ROLE%TYPE,
    ADMIN_OPTION    DBA_ROLE_PRIVS.ADMIN_OPTION%TYPE,
    DEFAULT_ROLE    DBA_ROLE_PRIVS.DEFAULT_ROLE%TYPE,
    DELEGATE_OPTION VARCHAR2(3),
    INHERITED       VARCHAR2(3),
    COMMON          VARCHAR2(3),
    CON_ID          NUMBER
  );

  I I_T;

  FUNCTION QA (IN_VALUE IN VARCHAR2) RETURN VARCHAR2 AS
    V_ENCLOSURE VARCHAR2(1) := '"';
    V_SEPARATOR VARCHAR2(1) := ',';
    OUT_VALUE   VARCHAR2(4000);
  BEGIN
    IF IN_VALUE IS NOT NULL THEN
      OUT_VALUE := REPLACE(REPLACE(IN_VALUE,CHR(13),' '),CHR(10),' ');
      IF OUT_VALUE LIKE '%' || V_ENCLOSURE || '%' OR OUT_VALUE LIKE '%' || V_SEPARATOR || '%' THEN
        RETURN V_ENCLOSURE || REPLACE(OUT_VALUE,V_ENCLOSURE,V_ENCLOSURE || V_ENCLOSURE) || V_ENCLOSURE;
      ELSE
        RETURN OUT_VALUE;
      END IF;
    ELSE
      RETURN NULL;
    END IF;
  END;

BEGIN
  DBMS_OUTPUT.ENABLE(NULL);

  SELECT SUBSTR(VERSION,1,INSTR(VERSION,'.',1,4)-1),SUBSTR(VERSION,1,INSTR(VERSION,'.',1,1)-1) INTO V_ORA_VERSION,V_ORA_VER_MAJOR FROM SYS.V$INSTANCE;
  IF v_ora_version = '11.2.0.4' THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.GRANTED_ROLE,
             P.ADMIN_OPTION,
             P.DEFAULT_ROLE,
             NULL DELEGATE_OPTION,
             NULL INHERITED,
             NULL COMMON,
             NULL CON_ID
      FROM   DBA_ROLE_PRIVS P
      WHERE (
        P.GRANTED_ROLE IN &&default_role_list_11g_1. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_2. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_3. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_4. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_5. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_6. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_7. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_8. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_9.
      )
      ORDER  BY 1,2,3,4]';
  ELSIF v_ora_version in ('12.1.0.1','12.1.0.2') THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.GRANTED_ROLE,
             P.ADMIN_OPTION,
             P.DEFAULT_ROLE,
             P.DELEGATE_OPTION,
             NULL INHERITED,
             P.COMMON,
             P.CON_ID
      FROM   CDB_ROLE_PRIVS P,
             CDB_ROLES R
      WHERE  P.GRANTED_ROLE = R.ROLE
      AND    P.CON_ID = R.CON_ID
      AND    R.ORACLE_MAINTAINED = 'Y'
      ORDER  BY 1,2,3,4]';
  ELSIF v_ora_ver_major >= 12 THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.GRANTED_ROLE,
             P.ADMIN_OPTION,
             P.DEFAULT_ROLE,
             P.DELEGATE_OPTION,
             P.INHERITED,
             P.COMMON,
             P.CON_ID
      FROM   CDB_ROLE_PRIVS P,
             CDB_ROLES R
      WHERE  P.GRANTED_ROLE = R.ROLE
      AND    P.CON_ID = R.CON_ID
      AND    R.ORACLE_MAINTAINED = 'Y'
      ORDER  BY 1,2,3,4]';
  ELSE
    V_SQL := q'[
      SELECT NULL GRANTEE,
             NULL GRANTED_ROLE,
             NULL ADMIN_OPTION,
             NULL DEFAULT_ROLE,
             NULL DELEGATE_OPTION,
             NULL INHERITED,
             NULL COMMON,
             NULL CON_ID
      FROM   DUAL
      WHERE  1=2]';
  END IF;

  OPEN OBJ FOR V_SQL;  

  CASE V_PERMS_TYPE
   WHEN 'PRIVS_ROL' THEN
    LOOP
      FETCH OBJ INTO I;
      EXIT WHEN OBJ%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(
      QA(I.GRANTEE) || V_SEPARATOR ||
      QA(I.GRANTED_ROLE) || V_SEPARATOR ||
      QA(I.ADMIN_OPTION) || V_SEPARATOR ||
      QA(I.DEFAULT_ROLE) || V_SEPARATOR ||
      QA(I.DELEGATE_OPTION) || V_SEPARATOR ||
      QA(I.INHERITED) || V_SEPARATOR ||
      QA(I.COMMON) || V_SEPARATOR ||
      QA(I.CON_ID));
    END LOOP;
   ELSE
    NULL;
  END CASE;
  CLOSE OBJ;

END;
/

DECLARE
  V_ENCLOSURE VARCHAR2(1) := '"';
  V_SEPARATOR VARCHAR2(1) := ',';
  V_ORA_VER_MAJOR NUMBER;
  V_ORA_VERSION VARCHAR2(20);
  V_SQL CLOB;

  V_PERMS_TYPE VARCHAR2(30) := UPPER('&2');

  TYPE OBJ_T IS REF CURSOR;
  OBJ OBJ_T;

  TYPE I_T IS RECORD (
    GRANTEE         DBA_ROLE_PRIVS.GRANTEE%TYPE,
    GRANTED_ROLE    DBA_ROLE_PRIVS.GRANTED_ROLE%TYPE,
    ADMIN_OPTION    DBA_ROLE_PRIVS.ADMIN_OPTION%TYPE,
    DEFAULT_ROLE    DBA_ROLE_PRIVS.DEFAULT_ROLE%TYPE,
    DELEGATE_OPTION VARCHAR2(3),
    INHERITED       VARCHAR2(3),
    COMMON          VARCHAR2(3),
    CON_ID          NUMBER
  );

  I I_T;

  FUNCTION QA (IN_VALUE IN VARCHAR2) RETURN VARCHAR2 AS
    V_ENCLOSURE VARCHAR2(1) := '"';
    V_SEPARATOR VARCHAR2(1) := ',';
    OUT_VALUE   VARCHAR2(4000);
  BEGIN
    IF IN_VALUE IS NOT NULL THEN
      OUT_VALUE := REPLACE(REPLACE(IN_VALUE,CHR(13),' '),CHR(10),' ');
      IF OUT_VALUE LIKE '%' || V_ENCLOSURE || '%' OR OUT_VALUE LIKE '%' || V_SEPARATOR || '%' THEN
        RETURN V_ENCLOSURE || REPLACE(OUT_VALUE,V_ENCLOSURE,V_ENCLOSURE || V_ENCLOSURE) || V_ENCLOSURE;
      ELSE
        RETURN OUT_VALUE;
      END IF;
    ELSE
      RETURN NULL;
    END IF;
  END;

BEGIN
  DBMS_OUTPUT.ENABLE(NULL);

  SELECT SUBSTR(VERSION,1,INSTR(VERSION,'.',1,4)-1),SUBSTR(VERSION,1,INSTR(VERSION,'.',1,1)-1) INTO V_ORA_VERSION,V_ORA_VER_MAJOR FROM SYS.V$INSTANCE;
  IF v_ora_version = '11.2.0.4' THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.GRANTED_ROLE,
             P.ADMIN_OPTION,
             P.DEFAULT_ROLE,
             NULL DELEGATE_OPTION,
             NULL INHERITED,
             NULL COMMON,
             NULL CON_ID
      FROM   DBA_ROLE_PRIVS P
      WHERE NOT (
        P.GRANTED_ROLE IN &&default_role_list_11g_1. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_2. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_3. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_4. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_5. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_6. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_7. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_8. OR
        P.GRANTED_ROLE IN &&default_role_list_11g_9.
      )
      ORDER  BY 1,2,3,4]';
  ELSIF v_ora_version in ('12.1.0.1','12.1.0.2') THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.GRANTED_ROLE,
             P.ADMIN_OPTION,
             P.DEFAULT_ROLE,
             P.DELEGATE_OPTION,
             NULL INHERITED,
             P.COMMON,
             P.CON_ID
      FROM   CDB_ROLE_PRIVS P,
             CDB_ROLES R
      WHERE  P.GRANTED_ROLE = R.ROLE
      AND    P.CON_ID = R.CON_ID
      AND    NOT(R.ORACLE_MAINTAINED = 'Y')
      ORDER  BY 1,2,3,4]';
  ELSIF v_ora_ver_major >= 12 THEN
    V_SQL := q'[
      SELECT P.GRANTEE,
             P.GRANTED_ROLE,
             P.ADMIN_OPTION,
             P.DEFAULT_ROLE,
             P.DELEGATE_OPTION,
             P.INHERITED,
             P.COMMON,
             P.CON_ID
      FROM   CDB_ROLE_PRIVS P,
             CDB_ROLES R
      WHERE  P.GRANTED_ROLE = R.ROLE
      AND    P.CON_ID = R.CON_ID
      AND    NOT(R.ORACLE_MAINTAINED = 'Y')
      ORDER  BY 1,2,3,4]';
  ELSE
    V_SQL := q'[
      SELECT NULL GRANTEE,
             NULL GRANTED_ROLE,
             NULL ADMIN_OPTION,
             NULL DEFAULT_ROLE,
             NULL DELEGATE_OPTION,
             NULL INHERITED,
             NULL COMMON,
             NULL CON_ID
      FROM   DUAL
      WHERE  1=2]';
  END IF;

  OPEN OBJ FOR V_SQL;  

  CASE V_PERMS_TYPE
   WHEN 'PRIVS_ROL_OTHERS' THEN
    LOOP
      FETCH OBJ INTO I;
      EXIT WHEN OBJ%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE(
      QA(I.GRANTEE) || V_SEPARATOR ||
      QA(I.GRANTED_ROLE) || V_SEPARATOR ||
      QA(I.ADMIN_OPTION) || V_SEPARATOR ||
      QA(I.DEFAULT_ROLE) || V_SEPARATOR ||
      QA(I.DELEGATE_OPTION) || V_SEPARATOR ||
      QA(I.INHERITED) || V_SEPARATOR ||
      QA(I.COMMON) || V_SEPARATOR ||
      QA(I.CON_ID));
    END LOOP;
   ELSE
    NULL;
  END CASE;
  CLOSE OBJ;

END;
/

SPOOL OFF