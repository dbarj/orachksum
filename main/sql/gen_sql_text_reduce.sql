-- Only External Table 1 is used in this code and must contain the Original CSV.
DEF orachk_sql_v_oraversion  = '&1.'
DEF orachk_sql_v_ps_type     = '&2.'
DEF orachk_sql_v_ps_value    = '&3.'
DEF orachk_sql_v_ojvm_psu    = '&4.'
-- orachk_sql_v_numcols must have total columns in the CSV file not considering filter cols (series, oraversion, psu_from, psu_to, flag)
DEF orachk_sql_v_numcols     = '&5.'
UNDEF 1 2 3 4 5

-- For version <= 11.2.0.4 those fields can be null
@@&&fc_set_value_var_nvl. 'orachk_sql_v_ojvm_psu'   '&&orachk_sql_v_ojvm_psu.'   '999999'
@@&&fc_set_value_var_nvl. 'orachk_sql_v_ps_value'   '&&orachk_sql_v_ps_value.'   '999999'

COL orachk_sql_c_series     NEW_V orachk_sql_c_series     NOPRI
COL orachk_sql_c_oraversion NEW_V orachk_sql_c_oraversion NOPRI
COL orachk_sql_c_psu_from   NEW_V orachk_sql_c_psu_from   NOPRI
COL orachk_sql_c_psu_to     NEW_V orachk_sql_c_psu_to     NOPRI
COL orachk_sql_c_flag       NEW_V orachk_sql_c_flag       NOPRI

select 'C' || (&&orachk_sql_v_numcols.+1) orachk_sql_c_series,
       'C' || (&&orachk_sql_v_numcols.+2) orachk_sql_c_oraversion,
       'C' || (&&orachk_sql_v_numcols.+3) orachk_sql_c_psu_from,
       'C' || (&&orachk_sql_v_numcols.+4) orachk_sql_c_psu_to,
       'C' || (&&orachk_sql_v_numcols.+5) orachk_sql_c_flag      
from   dual;

COL orachk_sql_c_series     CLEAR
COL orachk_sql_c_oraversion CLEAR
COL orachk_sql_c_psu_from   CLEAR
COL orachk_sql_c_psu_to     CLEAR
COL orachk_sql_c_flag       CLEAR

DEF orachk_sql_tab_name      = '&&orachk_obj_tab1.'

DECLARE
  v_orachk_sql_hashcol         VARCHAR2(4000);
  v_orachk_sql_collist         VARCHAR2(4000);
BEGIN

  with tab as (
    (select 'C' || rownum colname from dual connect by level <= &&orachk_sql_v_numcols.)
  )
  select 'sys.dbms_crypto.hash(rawtohex(' || listagg(colname,' || '';'' || ') within group(order by rownum) || '),2)',
  listagg(colname,',') within group(order by rownum)
  INTO v_orachk_sql_hashcol, v_orachk_sql_collist
  from tab;

  :sql_text := q'[
  with t2 as (
    select /*+ materialize */ ]' || v_orachk_sql_hashcol || q'[ hashid
    from &&orachk_sql_tab_name.
    where  &&orachk_sql_c_series. = 'OJVM'
    and    &&orachk_sql_c_oraversion. = '&&orachk_sql_v_oraversion.'
    and    ((&&orachk_sql_c_psu_from. = -1 and  &&orachk_sql_c_psu_to. = -1 and &&orachk_sql_v_ojvm_psu. > 0) or &&orachk_sql_v_ojvm_psu. between &&orachk_sql_c_psu_from. and &&orachk_sql_c_psu_to.)
  )
  select ]' || v_orachk_sql_collist || q'[ from &&orachk_sql_tab_name. t1
  where &&orachk_sql_c_series. in ('BOTH','&&orachk_sql_v_ps_type.')          -- v_source_col_series
  and   &&orachk_sql_c_oraversion. = '&&orachk_sql_v_oraversion.'                -- v_source_col_oraversion
  and   ]' || &&orachk_sql_v_ps_value. || q'[ between &&orachk_sql_c_psu_from. and &&orachk_sql_c_psu_to. -- v_source_col_psu_from and v_source_col_psu_to
  and ]' || v_orachk_sql_hashcol || q'[
  not in ( select hashid from t2 )
  union all
  select ]' || v_orachk_sql_collist || q'[ from &&orachk_sql_tab_name.
  where &&orachk_sql_c_series. = 'OJVM'               -- v_source_col_series
  and   &&orachk_sql_c_oraversion. = '&&orachk_sql_v_oraversion.'  -- v_source_col_oraversion
  and   &&orachk_sql_v_ojvm_psu. between &&orachk_sql_c_psu_from. and &&orachk_sql_c_psu_to. -- v_source_col_psu_from and v_source_col_psu_to
  and   &&orachk_sql_c_flag. is null                -- v_source_col_flag
  ]';
END;
/

UNDEF orachk_sql_v_oraversion
UNDEF orachk_sql_v_ojvm_psu
UNDEF orachk_sql_v_db_ru_psu
UNDEF orachk_sql_v_bp_rur_psu
UNDEF orachk_sql_v_numcols

UNDEF orachk_sql_c_series
UNDEF orachk_sql_c_oraversion
UNDEF orachk_sql_c_psu_from
UNDEF orachk_sql_c_psu_to
UNDEF orachk_sql_c_flag

UNDEF orachk_sql_tab_name
