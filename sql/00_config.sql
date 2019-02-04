-- moat369 configuration file. for those cases where you must change moat369 functionality

/*********************** software configuration (do not remove ) ************************/
@@00_software

/*************************** ok to modify (if really needed) ****************************/

-- Checksum Method
-- csv:   Nothing created on DB. Use awk to compare objects.
-- fast:  External tables created on DB. Extremely Fast SQL to compare.
DEF orachk_method = 'csv'

-- report column, or section, or range of columns or range of sections i.e. 3, 3-4, 3a, 3a-4c, 3-4c, 3c-4 / null means all (default)
DEF moat369_sections = ''

-- defines if the output will be encrypted using provided AEG certificate
DEF moat369_conf_encrypt_output = 'OFF'
DEF moat369_conf_encrypt_html   = 'OFF'
DEF moat369_conf_compress_html  = 'ON'

/**************************** not recommended to modify *********************************/

-- excluding some features from the reports substantially reduces usability with minimal performance gain
DEF moat369_conf_incl_tkprof   = 'N'
DEF moat369_conf_incl_opatch   = 'N'
DEF moat369_conf_ask_license   = 'N'
DEF moat369_conf_sql_format    = 'N'
DEF moat369_conf_sql_highlight = 'Y'
DEF moat369_conf_tablefilter   = 'Y'

/**************************** enter your modifications here *****************************/

--DEF moat369_sections = '6d-6e'
--DEF DEBUG      = 'ON'