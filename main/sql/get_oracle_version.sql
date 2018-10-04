SET SERVEROUTPUT ON FORMAT WRAPPED
SET FEEDBACK OFF
--SET HEADING OFF
SET TRIM ON
SET TRIMSPOOL ON
--SET TAB OFF
--SET LINESIZE 5000
--SET PAGESIZE 0
spool &1
DECLARE
  V_PSU_RU NUMBER;
  V_BP_RUR NUMBER;
  V_OJVM NUMBER;

  V_PSU_RU_DATE TIMESTAMP(6);
  V_BP_RUR_DATE TIMESTAMP(6);

  V_PS_TYPE VARCHAR2(20);
  V_PS_VALUE NUMBER;
  V_RUR_RUBASE VARCHAR2(20);

  V_ORA_VER_MAJOR NUMBER;
  V_ORA_VERSION VARCHAR2(20);

  V_ISCDB VARCHAR2(3);
  V_LIST_PDBS VARCHAR2(2000);

  PROCEDURE SET_DBPSU_OR_RU
  IS
  BEGIN
    IF v_ora_version = '11.2.0.4' THEN
      select ID, action_time into V_PSU_RU,V_PSU_RU_DATE
      from (
        select ID, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$history
        where version='11.2.0.4' and namespace='SERVER' and action='APPLY' and BUNDLE_SERIES='PSU'
      ) where ordem=1;
    ELSIF v_ora_version = '12.1.0.1' THEN
      select ID, action_time into V_PSU_RU,V_PSU_RU_DATE
      from (
        select ID, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$history
        where version='12.1.0.1' and namespace='SERVER' and action='APPLY' and BUNDLE_SERIES='PSU'
      ) where ordem=1;
    ELSIF v_ora_version = '12.1.0.2' THEN
      execute immediate q'[
      select BUNDLE_ID, action_time
      from (
        select BUNDLE_ID, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where version='12.1.0.2' and status='SUCCESS' and action='APPLY' and BUNDLE_SERIES='PSU'
      ) where ordem=1
      ]' into V_PSU_RU,V_PSU_RU_DATE;
    ELSIF v_ora_version = '12.2.0.1' THEN
      execute immediate q'[
      select BUNDLE_ID, action_time
      from (
        select BUNDLE_ID, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where version='12.2.0.1' and status='SUCCESS' and action='APPLY' and BUNDLE_SERIES='DBRU'
      ) where ordem=1
      ]' into V_PSU_RU,V_PSU_RU_DATE;
    ELSIF v_ora_ver_major > 12 THEN
      execute immediate q'[
      select ID, action_time
      from (
        select regexp_substr(substr(DESCRIPTION,instr(DESCRIPTION,'.',1,4)+1),'^[0-9]+') ID, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where source_version like :1 || '.%' and status='SUCCESS' and action='APPLY' and PATCH_TYPE='RU'
      ) where ordem=1
      ]' into V_PSU_RU,V_PSU_RU_DATE using v_ora_ver_major;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN V_PSU_RU:=0;
  END;
  PROCEDURE SET_OJVMPSU
  IS
  BEGIN
    IF v_ora_version = '11.2.0.4' THEN
      select decode(substr(version,a,b-a),6,160119,substr(version,a,b-a)) psu into V_OJVM
      from (
        select instr(version,'11.2.0.4.')+length('11.2.0.4.') a,instr(version,'OJVM') b,version,
        rank() over (order by action_time desc) ordem
        from sys.registry$history
        where version like '11.2.0.4.%' and namespace='SERVER' and action='jvmpsu.sql' and BUNDLE_SERIES is null
      ) where ordem=1;
    ELSIF v_ora_version = '12.1.0.1' THEN
      select decode(substr(version,a,b-a),6,160119,substr(version,a,b-a)) psu into V_OJVM
      from (
        select instr(version,'12.1.0.1.')+length('12.1.0.1.') a,instr(version,'OJVM') b,version,
        rank() over (order by action_time desc) ordem
        from sys.registry$history
        where version like '12.1.0.1.%' and namespace='SERVER' and action='jvmpsu.sql' and BUNDLE_SERIES is null
      ) where ordem=1;
    ELSIF v_ora_version = '12.1.0.2' THEN
      execute immediate q'[
      select substr(description,a,b-a)
      from (
        select version,instr(description,version)+length(version)+1 a,instr(description,',') b,description,
        rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where version='12.1.0.2' and status='SUCCESS' and action='APPLY' and BUNDLE_SERIES is null and upper(description) like '%PSU%JAVAVM%'
      ) where ordem=1
      ]' into V_OJVM;
    ELSIF v_ora_version = '12.2.0.1' THEN
      execute immediate q'[
      select substr(description,a,instr(description,' ',a)-a)
      from (
        select instr(description,version)+length(version)+1 a, description,
        rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where version='12.2.0.1' and status='SUCCESS' and action='APPLY' and BUNDLE_SERIES is null and upper(description) like '%OJVM RELEASE UPDATE%'
      ) where ordem=1
      ]' into V_OJVM;
    ELSIF v_ora_ver_major > 12 THEN
      execute immediate q'[
      select substr(version,a,b-a) psu
      from (
        select instr(version,'.',1,4)+1 a,instr(version,'OJVM') b,version,
        rank() over (order by action_time desc) ordem
        from sys.registry$history
        where version like :1 || '.%' and namespace='SERVER' and action='jvmpsu.sql' and BUNDLE_SERIES is null
      ) where ordem=1
      ]' into V_OJVM using v_ora_ver_major;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN V_OJVM:=0;
  END;
  PROCEDURE SET_DBBP_OR_RUR
  IS
  BEGIN
    IF v_ora_version = '11.2.0.4' THEN
      select replace(comments,'BP',''), action_time into V_BP_RUR, V_BP_RUR_DATE
      from (
        select comments, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$history
        where version='11.2.0.4' and namespace='SERVER' and action='APPLY' and BUNDLE_SERIES='EXA'
      ) where ordem=1;
    ELSIF v_ora_version = '12.1.0.1' THEN
      select ID, action_time into V_BP_RUR, V_BP_RUR_DATE
      from (
        select ID, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$history
        where version='12.1.0.1' and namespace='SERVER' and action='APPLY' and BUNDLE_SERIES='PSU'
      ) where ordem=1;
    ELSIF v_ora_version = '12.1.0.2' THEN
      execute immediate q'[
      select BUNDLE_ID, action_time
      from (
        select BUNDLE_ID, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where version='12.1.0.2' and status='SUCCESS' and action='APPLY' and BUNDLE_SERIES='DBBP'
      ) where ordem=1
      ]' into V_BP_RUR, V_BP_RUR_DATE;
    ELSIF v_ora_version = '12.2.0.1' THEN
      execute immediate q'[
      select BUNDLE_ID, action_time
      from (
        select BUNDLE_ID, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where version='12.2.0.1' and status='SUCCESS' and action='APPLY' and BUNDLE_SERIES like '%RUR'
      ) where ordem=1
      ]' into V_BP_RUR, V_BP_RUR_DATE;
    ELSIF v_ora_ver_major > 12 THEN
      execute immediate q'[
      select ID, action_time
      from (
        select substr(TARGET_VERSION,instr(TARGET_VERSION,'.',1,2)+1,instr(TARGET_VERSION,'.',1,3)-instr(TARGET_VERSION,'.',1,2)-1) ID, action_time, rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where source_version like :1 || '.%' and status='SUCCESS' and action='APPLY' and PATCH_TYPE='RUR'
      ) where ordem=1
      ]' into V_BP_RUR,V_BP_RUR_DATE using v_ora_ver_major;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN V_BP_RUR:=0;
  END;
  PROCEDURE SET_RUR_RUBASE
  IS
  BEGIN
    IF v_ora_version = '12.2.0.1' THEN
      execute immediate q'[
      select RU_BASE || 'RUR'
      from (
        select substr(BUNDLE_SERIES,instr(BUNDLE_SERIES,'RUR')-7,7) RU_BASE, rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where version='12.2.0.1' and status='SUCCESS' and action='APPLY' and BUNDLE_SERIES like '%RUR'
      ) where ordem=1
      ]' into V_RUR_RUBASE;
    ELSIF v_ora_ver_major > 12 THEN
      execute immediate q'[
      select RU_BASE || 'RUR'
      from (
        select substr(TARGET_VERSION,1,instr(TARGET_VERSION,'.',1,2)-1) RU_BASE, rank() over (order by action_time desc) ordem
        from sys.registry$sqlpatch
        where source_version like :1 || '.%' and status='SUCCESS' and action='APPLY' and PATCH_TYPE='RUR'
      ) where ordem=1
      ]' into V_RUR_RUBASE using v_ora_ver_major;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN V_RUR_RUBASE:=0;
  END;
  PROCEDURE SET_ISCDB
  IS
  BEGIN
    IF v_ora_version = '11.2.0.4' THEN
      select 'NO' into V_ISCDB from dual;
    ELSIF v_ora_ver_major >= 12 THEN
      execute immediate q'[select cdb from v$database]' into V_ISCDB;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN V_ISCDB:='NO';
  END;
  PROCEDURE SET_LIST_PDBS
  IS
  BEGIN
    IF v_ora_version = '11.2.0.4' THEN
      select '' into V_LIST_PDBS from dual;
    ELSIF v_ora_ver_major >= 12 THEN
      execute immediate q'[select listagg(con_id,',') within group(order by con_id) from sys.v$containers a where open_mode like 'READ%' order by 1]' into V_LIST_PDBS;
    END IF;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN V_ISCDB:='NO';
  END;  
BEGIN
  DBMS_OUTPUT.ENABLE(10000000);
  select substr(version,1,instr(version,'.',1,4)-1),substr(version,1,instr(version,'.',1,1)-1) into v_ora_version,v_ora_ver_major from sys.v$instance;
  IF v_ora_version NOT IN  ('11.2.0.4', '12.1.0.1', '12.1.0.2', '12.2.0.1', '18.0.0.0') THEN
    RAISE_APPLICATION_ERROR(-20000,'Unsupported Version');
  END IF;
  SET_DBPSU_OR_RU();
  SET_OJVMPSU();
  SET_DBBP_OR_RUR();
  SET_RUR_RUBASE();
  SET_LIST_PDBS();
  --SET_ISCDB();

  IF V_BP_RUR_DATE > V_PSU_RU_DATE OR (V_BP_RUR_DATE IS NOT NULL AND V_PSU_RU_DATE IS NULL)
  THEN
    IF V_ORA_VERSION IN ('11.2.0.4', '12.1.0.1', '12.1.0.2')
    THEN
      V_PS_TYPE := 'BP';
    ELSE
      V_PS_TYPE := V_RUR_RUBASE;
    END IF;
    V_PS_VALUE := V_BP_RUR;
  ELSE
    IF V_ORA_VERSION IN ('11.2.0.4', '12.1.0.1', '12.1.0.2')
    THEN
      V_PS_TYPE := 'PSU';
    ELSE
      V_PS_TYPE := 'RU';
    END IF;
    V_PS_VALUE := V_PSU_RU;
  END IF;

  DBMS_OUTPUT.PUT_LINE(V_ORA_VERSION);
  DBMS_OUTPUT.PUT_LINE(V_PS_TYPE);
  DBMS_OUTPUT.PUT_LINE(V_PS_VALUE);
  DBMS_OUTPUT.PUT_LINE(V_OJVM);
  DBMS_OUTPUT.PUT_LINE(V_LIST_PDBS);
  --DBMS_OUTPUT.PUT_LINE(V_ISCDB);
END;
/
SPOOL OFF
--EXIT SQL.SQLCODE