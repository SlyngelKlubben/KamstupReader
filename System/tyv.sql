 -- Create table tyv
create table tyv();
alter table tyv add id serial;
alter table tyv add timestamp timestamp default current_timestamp;
alter table tyv add content text;
