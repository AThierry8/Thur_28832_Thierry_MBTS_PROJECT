-- creating a new tablespace
create tablespace mbts_data datafile 'C:\APP\ATHIERRY\PRODUCT\23AI\ORADATA\FREE\thur_28832_Thierry_MBTS_DB\mbts_data01.dbf' 
size 500M autoextend on next 100M maxsize unlimited;
--  creating a new user and granting necessary privileges
create user mbts_user identified by 2527 default tablespace mbts_data;
grant connect, resource, dba to mbts_user;  
CONNECT mbts_user/2527@localhost:1521/thur_28832_Thierry_MBTS_DB;
show con_name;
show user; 