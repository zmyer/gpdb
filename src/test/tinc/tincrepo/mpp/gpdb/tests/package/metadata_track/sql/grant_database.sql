create user mdt_user1 with superuser;
create group mdt_group1 with superuser;

create database mdt_db_1;
grant create on database mdt_db_1 to mdt_user1 with grant option;

create database mdt_db_2;
grant connect on database mdt_db_2 to group mdt_group1 with grant option;

create database mdt_db_3;
grant all privileges on database mdt_db_3 to public;

create database mdt_db_4;
grant all on database mdt_db_4 to public;

create database mdt_db_5;
grant TEMPORARY on database mdt_db_5 to mdt_user1 with grant option;

create database mdt_db_6;
grant TEMP on database mdt_db_6 to group mdt_group1 with grant option;

drop database mdt_db_1;
drop database mdt_db_2;
drop database mdt_db_3;
drop database mdt_db_4;
drop database mdt_db_5;
drop database mdt_db_6;
drop user mdt_user1;
drop group mdt_group1;
