-- start_ignore
SET gp_create_table_random_default_distribution=off;
-- end_ignore

set time zone PST8PDT;

-- Insert into delta compressable data types with delta range that is less than 2 bytes

-- start_ignore
Drop table if exists delta_2_byte;
-- end_ignore

Create table delta_2_byte(
    i int, 
    a1 integer, 
    a2 bigint, 
    a3 date, 
    a4 time, 
    a5 timestamp, 
    a6 timestamp with time zone
    ) with(appendonly=true, orientation=column, compresstype=rle_type); 

-- Inserts such that the values goes to a single segment. this can ensure a constant compression ratio for comparison
Insert into delta_2_byte values 
    (1, 1, 2147483648, '2004-07-29', '14:22:23.776892', '2014-07-30 14:22:58.356229', '2014-07-30 14:22:23.776892-07'),
    (1, 1000, 2147479999, '2014-07-31', '14:22:23.778899-07', '2014-07-30 14:22:58.357229', '2014-07-30 14:22:23.778899-07');

Select 'compression_ratio' as compr_ratio, get_ao_compression_ratio('delta_2_byte');

Select * from delta_2_byte order by a1;

 

