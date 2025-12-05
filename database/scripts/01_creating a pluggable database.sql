--creating a pluggable database
create pluggable database thur_28832_Thierry_MBTS_DB ADMIN USER Thierry 
IDENTIFIED by 2527 
FILE_NAME_CONVERT = (
    'C:\APP\ATHIERRY\PRODUCT\23AI\ORADATA\FREE\PDBSEED\',
    'C:\APP\ATHIERRY\PRODUCT\23AI\ORADATA\FREE\thur_28832_Thierry_MBTS_DB\'
);
--opening the pluggable database
alter pluggable database thur_28832_Thierry_MBTS_DB open;
--connecting to the pluggable database
connect Thierry/2527@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)
(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=thur_28832_Thierry_MBTS_DB)));
--verifying the connection
select sys_context('USERENV','CURRENT_USER') from dual;

select name from v$database;
select name, open_mode from v$pdbs;
alter session set container=thur_28832_Thierry_MBTS_DB;

alter pluggable database thur_28832_thierry_MBTS_DB open;
alter session set  container = thur_28832_Thierry_MBTS_DB
select name , open_mode from v$pdbs;
show con_name;
show user;
create tablespace mbts_data datafile 'C:\APP\ATHIERRY\PRODUCT\23AI\ORADATA\FREE\thur_28832_Thierry_MBTS_DB\mbts_data01.dbf' 
size 500M autoextend on next 100M maxsize unlimited;
create user mbts_user identified by 2527 default tablespace mbts_data;
grant create session, create table, create view, create procedure, create sequence, create trigger, unlimited tablespace to mbts_user;
connect mbts_user/2527@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=localhost)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=thur_28832_Thierry_MBTS_DB)));
