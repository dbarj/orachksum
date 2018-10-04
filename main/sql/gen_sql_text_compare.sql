-- Both External Table 1 and 2 are used. Output will be External Table 1 contents that does not exist on External Table 2.
DEF orachk_sql_v_numcols     = '&1.'
@@&&fc_def_empty_var. 2
@@&&fc_def_empty_var. 3
DEF orachk_sql_v_compare_rec = '&2.'
DEF orachk_sql_v_common_col  = '&3.'
UNDEF 1 2 3

DEF orachk_sql_tab_name1      = '&&orachk_obj_tab1.'
DEF orachk_sql_tab_name2      = '&&orachk_obj_tab2.'

DECLARE
  v_orachk_sql_collist  VARCHAR2(4000);
  v_orachk_sql_sellist  VARCHAR2(4000);
  v_orachk_sql_hash     VARCHAR2(4000);
  v_orachk_sql_hash_common   VARCHAR2(4000); -- This variable will receive all columns for report compare including COMMON column
  v_orachk_sql_hash_nocommon VARCHAR2(4000); -- This variable will receive all columns for report compare excluding COMMON column

  v_colcomp_fld_sep VARCHAR2(1 CHAR):= ',';
  v_colcomp_rec_sep VARCHAR2(1 CHAR):= ';';
BEGIN

  -- Generate compare line for SELECT
  with tabcols (col_seq) as ( -- Generate one row per column
    select rownum from dual connect by level <= &&orachk_sql_v_numcols.
  ),
  t_ap ( value, start_pos, end_pos ) AS ( -- Break compcol in one record per row (phase 1)
    SELECT value, 1, INSTR( value, v_colcomp_rec_sep )
    FROM (SELECT '&&orachk_sql_v_compare_rec.' value FROM DUAL)
    UNION ALL
    SELECT value, end_pos + 1, INSTR( value, v_colcomp_rec_sep, end_pos + 1 )
    FROM t_ap
    WHERE end_pos > 0
  ),
  s_ap (reprec) AS ( -- Break compcol in one record per row (phase 2)
    SELECT SUBSTR( value, start_pos, DECODE( end_pos, 0, LENGTH( value ) + 1, end_pos ) - start_pos )
    FROM t_ap
  ),
  f_ap (col_rep, col_comp) as ( -- Break compcol row in 2 columns
    select /*+ materialize */
     substr(reprec,1,instr(reprec,v_colcomp_fld_sep)-1),
     substr(reprec,instr(reprec,v_colcomp_fld_sep)+1)
    from s_ap
  ),
  resultcols (col_compare, col_report, col_position) as ( -- Create list of columns with NVL in case compare column exists
  select 
   nvl2(f1.col_rep,'NVL(C'||f1.col_comp||',C'||f1.col_rep||')','C'||col_seq),
   'C'||col_seq,
   rank() over (order by col_seq)
  from  tabcols,f_ap f1,f_ap f2
  where col_seq=f2.col_comp (+)
  and   f2.col_comp is null
  and   col_seq=f1.col_rep (+)
  )
  -- Create comma separated list of columns
  select --listagg(col_compare || ' COL_' || col_position,', ') within group(order by col_position),
         --listagg(DECODE(col_position,'&&orachk_sql_v_common_col.','NULL',col_compare) || ' COL_' || col_position,', ') within group(order by col_position),
         listagg(col_report || ' COL_' || col_position,', ') within group(order by col_position),
         listagg('COL_' || col_position || ' C' || col_position,', ') within group(order by col_position),
         'sys.dbms_crypto.hash(rawtohex(' || listagg(col_compare,' || '';'' || ') within group(order by col_position) || '),2)',
         'sys.dbms_crypto.hash(rawtohex(' || listagg(DECODE(col_position,'&&orachk_sql_v_common_col.','NULL',col_compare),' || '';'' || ') within group(order by col_position) || '),2)'
  into   v_orachk_sql_sellist,
         v_orachk_sql_collist,
         v_orachk_sql_hash_common,
         v_orachk_sql_hash_nocommon
  from   resultcols
  ;

  IF '&&is_cdb.' = 'Y'
  THEN
    v_orachk_sql_hash := v_orachk_sql_hash_common;
  ELSE
    v_orachk_sql_hash := v_orachk_sql_hash_nocommon;
  END IF;

  :sql_text := q'[
  with T1 as (
    select ]' || v_orachk_sql_sellist || q'[,
           ]' || v_orachk_sql_hash || q'[ HASH_ID
    from   &&orachk_sql_tab_name1.
  ),
  T2 as (
    select ]' || v_orachk_sql_hash || q'[ HASH_ID
    from   &&orachk_sql_tab_name2.
  )
  select ]' || v_orachk_sql_collist || q'[
  from   T1, T2
  where  T1.HASH_ID = T2.HASH_ID (+)
  and    T2.HASH_ID is null
  ]';

/*
  :sql_text := q'[
  select ]' || v_orachk_sql_collist || q'[ from
  (
   select ]' || v_orachk_sql_replist || q'[
   from   &&orachk_sql_tab_name1.
   minus
   select ]' || v_orachk_sql_replist || q'[
   from   &&orachk_sql_tab_name2.
  )
  ]';
*/

END;
/

UNDEF orachk_sql_v_numcols
UNDEF orachk_sql_v_compare_rec

UNDEF orachk_sql_tab_name1
UNDEF orachk_sql_tab_name2
