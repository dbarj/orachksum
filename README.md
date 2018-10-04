# ORACHKSUM - Oracle Database Integrity Checker #

ORACHKSUM is a tool to verify signature for files and internal objects of Oracle Databases. 
It gives a glance of a database security state. It also helps to document any findings.
ORACHKSUM installs nothing. For better results execute connected as SYS or DBA.
It takes around one hour to execute. Output ZIP file can be large (several MBs), so
you may want to execute ORACHKSUM from a system directory with at least 1 GB of free space.

ORACHKSUM uses [moat369](https://github.com/dbarj/moat369) API to generate html and graphs output.

## Supported Versions ##

* 11.2.0.4
* 12.1.0.2
* 12.2.0.1
* 18c

The ORACHKSUM signature dictionary file includes changes performed by PSU, BP, RU, RUR or OJVM PSU for the above releases.
Only if you have one-off patches applied that you could have some false-positives during scans.

## Currently dictionary objects scans ##

* Objects in CDB_SOURCE:
  * FUNCTION
  * JAVA SOURCE
  * LIBRARY
  * PACKAGE
  * PACKAGE BODY
  * PROCEDURE
  * TRIGGER
  * TYPE
  * TYPE BODY
* Views
* Default Privileges:
  * Tables
  * Columns
  * System
  * Role
* Synonyms
* Tablespace Quotas
* Java Policies
* VPD Policies
* Scheduler Objects:
  * Legacy Jobs
  * Scheduler Jobs
  * Scheduler Programs
* Audits:
  * Object Audit Options
  * Statement Audit Options
  * Privileges Audit Options
  * Audit Policies
  * Audit Policy Columns
  * Audit Unified Policies

## Execution Steps ##

1. Download and unzip orachksum-master.zip, navigate to the root orachksum-master directory.

```
$ wget -O orachksum-master.zip https://github.com/dbarj/orachksum/archive/master.zip
$ unzip orachksum-master.zip
$ cd orachksum-master/
```

2. Download and unzip latest moat369-master.zip API inside orachksum_master directory. Rename extract folder to moat369.

```
$ wget -O moat369.zip https://github.com/dbarj/moat369/archive/master.zip
$ unzip moat369.zip
$ mv moat369-master/ moat369/
```

3. Connect as SYS, DBA, or any User with Data Dictionary access:

```
$ sqlplus / as sysdba
```

4. Execute orachksum.sql.

```
SQL> @orachksum.sql
```

5. Unzip output ORACHKSUM_dbname_hostname_YYYYMMDD_HH24MI.zip into a directory on your PC

6. Review main html file 00001_orachksum_dbname_index.html

## Notes ##

1. As orachksum can run for a long time, in some systems it's recommend to execute it unattended:

```
$ nohup sqlplus / as sysdba @orachksum.sql &
```

2. If you need to execute ORACHKSUM against all databases in host use then orachksum.sh:

```
$ sh orachksum.sh
```

3. If you need to execute only a portion of ORACHKSUM (i.e. a column, section or range) use 
   these commands. Notice first parameter can be set to one section (i.e. 3b),
   one column (i.e. 3), a range of sections (i.e. 5c-6b) or range of columns (i.e. 5-7):

```
SQL> @orachksum.sql 3b
```

   note: valid column range for first parameter is 1 to 3. 

## Versions ##
* 1801 (2018-01-10)
  - Initial Version
* 1804 (2018-04-30)
  - Included Fast AWK Modes
* 1810 (2018-10-01)
  - Minor Improvements. First Public Release.