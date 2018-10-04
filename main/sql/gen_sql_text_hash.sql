-- Both External Table 1 and 2 are used.
-- Output will be External Table 1 contents that does not exist on External Table 2.
DEF orachk_sql_v_numcols_t2  = '&1.'
@@&&fc_def_empty_var. 2
DEF orachk_sql_v_compare_rec = '&2.'
UNDEF 1 2

DEF orachk_sql_tab_name1 = '&&orachk_obj_tab1.'
DEF orachk_sql_tab_name2 = '&&orachk_obj_tab2.'

COL orachk_sql_v_numcols_t1 NEW_V orachk_sql_v_numcols_t1

select TRIM(&&orachk_sql_v_numcols_t2. +
       NVL(REGEXP_COUNT('&&orachk_sql_v_compare_rec.',';'),0) +
       NVL2('&&orachk_sql_v_compare_rec.',1,0)) orachk_sql_v_numcols_t1
FROM   dual;

COL orachk_sql_v_numcols_t1 CLEAR

DEF orachk_sql_tab_hashcol_t1 = "C&&orachk_sql_v_numcols_t1."
DEF orachk_sql_tab_hashcol_t2 = "C&&orachk_sql_v_numcols_t2."


DECLARE
  v_orachk_sql_collist VARCHAR2(4000);
  v_orachk_sql_outlist VARCHAR2(4000);

  v_orachk_sql_hashid_t1 VARCHAR2(4000);
  v_orachk_sql_hashid_t2 VARCHAR2(4000);

  v_colcomp_fld_sep VARCHAR2(1 CHAR):= ',';
  v_colcomp_rec_sep VARCHAR2(1 CHAR):= ';';

BEGIN

  -- Generate compare line for SELECT
  with tabcols (col_seq) as -- Generate one row per column
  ( select rownum from dual connect by level <= &&orachk_sql_v_numcols_t1. - 1
  ),
  t_ap ( value, start_pos, end_pos ) AS -- Break compcol in one record per row (phase 1)
  ( SELECT value, 1, INSTR( value, v_colcomp_rec_sep ) FROM (SELECT '&&orachk_sql_v_compare_rec.' value FROM DUAL)
  UNION ALL
  SELECT value,
    end_pos                    + 1,
    INSTR( value, v_colcomp_rec_sep, end_pos + 1 )
  FROM t_ap
  WHERE end_pos > 0
  ),
  s_ap (reprec) AS -- Break compcol in one record per row (phase 2)
  ( SELECT SUBSTR( value, start_pos, DECODE( end_pos, 0, LENGTH( value ) + 1, end_pos ) - start_pos )
  FROM t_ap
  ),
  f_ap (col_rep, col_comp) as -- Break compcol row in 2 columns
  ( select /*+ materialize */ substr(reprec,1,instr(reprec,v_colcomp_fld_sep)-1), substr(reprec,instr(reprec,v_colcomp_fld_sep)+1) from s_ap
  ),
  resultcols (col_compare, col_output, col_position, col_total) as -- Create list of columns with NVL in case compare column exists
  (select nvl2(f1.col_rep,'NVL(C'||f1.col_comp||',C'||f1.col_rep||')','C'||col_seq),
          'C'||col_seq,
          rank() over (order by col_seq),
          count(*) over ()
  from  tabcols,f_ap f1,f_ap f2
  where col_seq=f2.col_comp (+)
  and   f2.col_comp is null
  and   col_seq=f1.col_rep (+)
  )
  -- Create comma separated list of columns
  select listagg('COL_' || col_position || ' C' || col_position,', ') within group(order by col_position),
         listagg(col_output || ' COL_' || col_position,', ') within group(order by col_position),
         'sys.dbms_crypto.hash(rawtohex(' || listagg('C' || col_position,' || '';'' || ') within group(order by col_position) || '),2)',
         --'sys.dbms_crypto.hash(rawtohex(' || listagg(decode(col_position,col_total,'CASE WHEN ' || col_compare || ' > 2 THEN ''2'' ELSE ' || col_compare || ' END',col_compare),' || '';'' || ') within group(order by col_position) || '),2)'
         'sys.dbms_crypto.hash(rawtohex(' || listagg(col_compare,' || '';'' || ') within group(order by col_position) || '),2)'
  into   v_orachk_sql_collist,
         v_orachk_sql_outlist,
         v_orachk_sql_hashid_t2,
         v_orachk_sql_hashid_t1
  from   resultcols
  ;

  :sql_text := q'[
  with T1 as ( -- Database Table
  select ]' || v_orachk_sql_outlist || q'[,
         &&orachk_sql_tab_hashcol_t1. HASHCOL,
         ]' || v_orachk_sql_hashid_t1 || q'[ IDCOL
  from   &&orachk_sql_tab_name1.
  ),
  T2 as ( -- Original Table
  select &&orachk_sql_tab_hashcol_t2. HASHCOL,
         ]' || v_orachk_sql_hashid_t2 || q'[ IDCOL
  from   &&orachk_sql_tab_name2.
  ),
  T3 as ( -- Original Table Unique IDCOLS
  select distinct ]' || v_orachk_sql_hashid_t2 || q'[ IDCOL
  from   &&orachk_sql_tab_name2.
  )
  select ]' || v_orachk_sql_collist || q'[, DECODE(T3.IDCOL,NULL,'NOT FOUND','NO MATCH') &&orachk_sql_tab_hashcol_t2.
  from   T1, T3
  where  T1.IDCOL=T3.IDCOL(+)
  and    (T1.HASHCOL,T1.IDCOL) not in (select T2.HASHCOL,T2.IDCOL from T2)
  ]';

END;
/

UNDEF orachk_sql_v_numcols_t1
UNDEF orachk_sql_v_numcols_t2
UNDEF orachk_sql_v_compare_rec

UNDEF orachk_sql_tab_hashcol_t1
UNDEF orachk_sql_tab_hashcol_t2

UNDEF orachk_sql_tab_name1
UNDEF orachk_sql_tab_name2
