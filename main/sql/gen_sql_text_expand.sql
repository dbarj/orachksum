-- Only External Table 1 is used in this code and must contain the Original CSV.
-- orachk_sql_v_incl_root will define if ROOT will be included in the expanded output (when connected in a PDB and want to analyse source)
-- orachk_sql_v_conid_pos is CON_ID position in table.
DEF orachk_sql_v_pdblist   = '&1.'
DEF orachk_sql_v_lastcol   = '&2.'
DEF orachk_sql_v_conid_pos = '&3.'
DEF orachk_sql_v_incl_root = '&4.'
UNDEF 1 2 3 4

COL orachk_sql_c_conid NEW_V orachk_sql_c_conid NOPRI

select 'C' || &&orachk_sql_v_conid_pos. orachk_sql_c_conid    
from   dual;

COL orachk_sql_c_conid CLEAR

DEF orachk_sql_tab_name1      = '&&orachk_obj_tab1.'

DECLARE
  v_orachk_sql_collist VARCHAR2(4000);
  v_con_id_column_str  VARCHAR2(50) := '"_CONID_"';
BEGIN

  with tab as (
    (select DECODE(level,'&&orachk_sql_v_conid_pos.',v_con_id_column_str,'C' || rownum) colname from dual connect by level <= &&orachk_sql_v_lastcol.) -- Skip last column (CON_ID)
  )
  select listagg(colname,',') within group(order by rownum)
  INTO v_orachk_sql_collist
  from tab;

  :sql_text := q'[
  WITH t ( value, start_pos, end_pos ) AS
    ( SELECT value, 1, INSTR( value, ',' ) FROM (SELECT '&&orachk_sql_v_pdblist.' value FROM DUAL)
    UNION ALL
    SELECT value,
      end_pos                    + 1,
      INSTR( value, ',', end_pos + 1 )
    FROM t
    WHERE end_pos > 0
    ),
  cons (con_id) as
    (SELECT /*+ materialize*/ SUBSTR( value, start_pos, DECODE( end_pos, 0, LENGTH( value ) + 1, end_pos ) - start_pos )
     FROM t)
  --------------------------------
  -- For PDBs when in connected to a CDB / SYS_CONTEXT('USERENV', 'CON_ID') = 1
  --------------------------------
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'CON_ID &&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1, (select distinct con_id from cons) T2
  where  T1.&&orachk_sql_c_conid. = 0 -- If CON_ID is 0, do a cartesian join.
  and    '&&orachk_sql_v_pdblist.' != '0' -- Multitenant
  and    SYS_CONTEXT('USERENV', 'CON_ID') = 1 -- Connected in ROOT
  union all
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'&&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1
  where  T1.&&orachk_sql_c_conid. in (1,2) -- If CON_ID is 1 or 2, don't do a cartesian join.
  and    '&&orachk_sql_v_pdblist.' != '0' -- Multitenant
  and    SYS_CONTEXT('USERENV', 'CON_ID') = 1 -- Connected in ROOT
  union all
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'CON_ID &&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1, (select distinct con_id from cons where con_id >= 3) T2
  where  T1.&&orachk_sql_c_conid. = 3 -- If CON_ID is 3, do a cartesian join only for con_id >= 3.
  and    '&&orachk_sql_v_pdblist.' != '0' -- Multitenant
  and    SYS_CONTEXT('USERENV', 'CON_ID') = 1 -- Connected in ROOT
  union all
  --------------------------------
  -- For PDBs when connected to a PDB / SYS_CONTEXT('USERENV', 'CON_ID') > 1
  --------------------------------
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'''&&orachk_sql_v_pdblist.'' &&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1
  where  T1.&&orachk_sql_c_conid. = 0 -- If CON_ID is 0, bring orachk_sql_v_pdblist value.
  and    '&&orachk_sql_v_pdblist.' != '0' -- Multitenant
  and    SYS_CONTEXT('USERENV', 'CON_ID') > 1 -- Not connected in ROOT
  union all
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'&&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1
  where  T1.&&orachk_sql_c_conid. = 1 -- If CON_ID is 1, bring only if variable below is set.
  and    '&&orachk_sql_v_incl_root.' = 'Y' -- Only include ROOT container if orachk_sql_v_incl_root is not null.
  and    '&&orachk_sql_v_pdblist.' != '0' -- Multitenant
  and    SYS_CONTEXT('USERENV', 'CON_ID') > 1 -- Not connected in ROOT
  union all
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'&&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1
  where  T1.&&orachk_sql_c_conid. = 2 -- If CON_ID is 2, bring it if connected to it.
  and    '&&orachk_sql_v_incl_root.' = 'N' -- Only include the 2nd container if orachk_sql_v_incl_root is null (THIS IS TEMPORARY TO AVOID BEING INCLUDED TWICE BY TEMP CODE BELOW AND WILL BE REMOVED IN THE FUTURE)
  and    '&&orachk_sql_v_pdblist.' != '0' -- Multitenant
  and    SYS_CONTEXT('USERENV', 'CON_ID') = 2 -- Not connected in ROOT
  union all
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'''&&orachk_sql_v_pdblist.'' &&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1
  where  T1.&&orachk_sql_c_conid. = 3 -- If CON_ID is 3, bring orachk_sql_v_pdblist value if it is 3 or bigger.
  and    '&&orachk_sql_v_pdblist.' != '0' -- Multitenant
  and    SYS_CONTEXT('USERENV', 'CON_ID') >= 3 -- Not connected in ROOT
  union all
  -- THE CODE BELOW IS TEMPORARY - WORKS FOR CONNECTED IN CDB AND PDB
  -- Adapt an error in logic for HASH generated tables. In future CON_ID=2 in HASH should be also included as 3, and thus create the ID 0.
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'CON_ID &&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1, (select distinct con_id from cons) T2
  where  T1.&&orachk_sql_c_conid. = 2 -- If CON_ID is 1 or 2, don't do a cartesian join.
  and    '&&orachk_sql_v_incl_root.' = 'Y'
  and    '&&orachk_sql_v_pdblist.' != '0' -- Multitenant
  and    SYS_CONTEXT('USERENV', 'CON_ID') >= 1
  -- END OF TEMPORARY CODE
  union all
  --------------------------------
  -- For Non-CDBs / '&&orachk_sql_v_pdblist.' = '0'
  --------------------------------
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'''0'' &&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1
  where  T1.&&orachk_sql_c_conid. in (0,1) -- If CON_ID is 0 or 1 for Non-CDBs.
  and    '&&orachk_sql_v_pdblist.' = '0' -- Non-CDB
  union all
  --------------------------------
  -- For 11g OR CSVs with empty CON_ID (like Files csv)
  --------------------------------
  select ]' || REPLACE(v_orachk_sql_collist,v_con_id_column_str,'&&orachk_sql_c_conid.') || q'[
  from   &&orachk_sql_tab_name1. T1
  where  '&&orachk_sql_v_pdblist.' IS NULL OR T1.&&orachk_sql_c_conid. IS NULL
  ]';
END;
/

UNDEF orachk_sql_v_lastcol orachk_sql_v_pdblist orachk_sql_v_conid_pos orachk_sql_v_incl_root

UNDEF orachk_sql_c_conid

UNDEF orachk_sql_tab_name1
