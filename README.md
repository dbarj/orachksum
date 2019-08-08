# ORACHKSUM - Oracle Database Integrity Checker #

Oracle Database Integrity Checker (**ORACHKSUM**) is a tool that verifies signature for files and internal objects of Oracle Databases, comparing what you have with what oracle provides in the original database installation. The tool is a basically a collection of SQLs and CSVs files, that will create and compare the sha1sum of your objects with the original ones and output the differences in a HTML report.

The tool installs nothing on the database, and all it needs is read privileges on your dictionary tables. It takes around 30 minutes to execute.

Output ZIP file can be large (several MBs), so you may want to execute ORACHKSUM from a system directory with at least 1 GB of free space.

ORACHKSUM uses [moat369](https://github.com/dbarj/moat369) API to generate html and graphs output. If you are familiar to edb360 and sqld360, you will notice they all have the same Look'n Feel.

## Supported Versions ##

ORACHKSUM was tested in **Linux** and **Solaris**. It may also work in Windows if executed with cygwin. As it creates nothing inside the database, the comparison is done using some underlying OS utilities like *grep, awk and sed*.

Curently, it supports the following Oracle DB versions:

* 11.2.0.4
* 12.1.0.2
* 12.2.0.1
* Any 18c

The ORACHKSUM signature dictionary files include changes performed by any **PSU, BP, RU, RUR or OJVM PSU** for the above releases.
If you have one-off patches applied on your database you may face some false-positives results during scans.

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
* Database Vault:
  * Realms
  * Realm Auths
  * Realm Objects
  * Rules
  * Rule Set
  * Command Rules
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

## Types of Scans ##

The ORACHKSUM utility executes 2 types of compares to verify for integrity changes:

1. **Sum Compares** - For all objects that exists in DBA_SOURCE (Packages, Triggers, etc), all VIEWS and also some database files (like $ORACLE_HOME/rdbms/sql/), the tool will compare the sha1sum of the object in the target database with the one created originally by oracle. The tool will also show **matches** and **no matches** in pie graph of the section 1a:

2. **Line Compares** - For all the other type of objects (like privileges, jobs, audits, etc), the tool will fully compare what you have with the oracle initially install using a **_diff_** of your table with the oracle original table. Thus, for each type of object, there will be 2 reports: one showing the extra lines you have and the other showing what is missing in your database:

## Execution Steps ##

1. Download and unzip latest orachksum version and, navigate to the root of orachksum-master directory:

```
$ wget -O orachksum.zip https://github.com/dbarj/orachksum/archive/master.zip
$ unzip orachksum.zip
$ cd orachksum-master/
```

2. Download and unzip latest moat369 API inside orachksum_master directory. Rename extract folder to moat369:

```
$ wget -O moat369.zip https://github.com/dbarj/moat369/archive/master.zip
$ unzip moat369.zip
$ mv moat369-master/ moat369/
```

3. Connect as SYS, DBA, or any User with Data Dictionary access:

```
$ sqlplus / as sysdba
```

4. Execute orachksum.sql:

```
SQL> @orachksum.sql
```

## Results ##

1. Unzip output **ORACHKSUM_dbname_hostname_YYYYMMDD_HH24MI.zip** into a directory on your PC.

2. Review main html file **00001_orachksum_dbname_index.html**.

## Notes ##

1. As orachksum can run for a long time, in some systems it's recommend to execute it unattended:

```
$ nohup sqlplus / as sysdba @orachksum.sql &
```

2. If you need to execute ORACHKSUM against all databases in your host, use **orachksum.sh**:

```
$ sh orachksum.sh
```

3. If you need to execute only a portion of ORACHKSUM (i.e. a column, section or range), add a parameter. Notice first parameter can be set to one section (i.e. 1b), one column (i.e. 1), a range of sections (i.e. 1c-2a) or range of columns (i.e. 1-2):

```
SQL> @orachksum.sql 3b
```

Note: valid column range for first parameter is 1 to 3. 

## Latest change ##

* 1905 (2019-08-04)
  - Included 2019-Jul CPU.
  - Removed some repetitive calls for exclude_seed_cdb_view.

Check **CHANGELOG.md** for more info.