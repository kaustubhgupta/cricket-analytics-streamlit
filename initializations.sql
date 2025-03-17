create warehouse dbt_usage;
create database cricketanalytics;
create schema raw;
use schema raw;

create sequence seq_matches;
create sequence seq_players;
create sequence seq_teams;

create storage integration s3_int
type = external_stage
storage_provider = s3
enabled = True
storage_aws_role_arn = ''
storage_allowed_locations = ('');

show storage integrations;

describe storage integration s3_int; -- STORAGE_AWS_IAM_USER_ARN & STORAGE_AWS_EXTERNAL_ID

create stage s3_ext_stage
storage_integration = s3_int
file_format = (TYPE = JSON)
url = ''

describe stage s3_ext_stage;

create table raw_data(
raw_json variant,
filename string,
load_date timestamp
);

create or replace pipe s3_to_snowflake auto_ingest=True as
copy into raw_data 
from (select $1, metadata$filename, current_timestamp from @s3_ext_stage)
on_error=continue
;

describe pipe s3_to_snowflake;

truncate raw_data;
select * from raw_data;

select system$pipe_status('s3_to_snowflake');

create user ''
password='';

create role dbt_usage;

create schema tranformed_data;

grant role dbt_usage to user '';

grant all on database cricketanalytics to role dbt_usage;
grant all on schema tranformed_data to role dbt_usage;


grant usage on warehouse dbt_usage to role dbt_usage;
grant usage on database cricketanalytics to role dbt_usage;
grant usage on schema tranformed_data to role dbt_usage;
grant select on all tables in schema raw to role dbt_usage;
grant select,insert,update,delete on all tables in schema tranformed_data to role dbt_usage;


grant all on schema tranformed_data to role accountadmin;
grant select on all tables in schema tranformed_data to role accountadmin;

grant usage on sequence seq_matches to role dbt_usage;
