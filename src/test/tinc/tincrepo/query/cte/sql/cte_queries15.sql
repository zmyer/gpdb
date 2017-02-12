-- @author prabhd 
-- @created 2012-02-01 12:00:00 
-- @modified 2013-02-01 12:00:00 
-- @tags cte HAWQ 
-- @product_version gpdb: [4.3-],hawq: [1.1-]
-- @db_name world_db
-- @description cte tests from cdbfast 

-- negative case. RECURSIVE WITH clause should fail 

with recursive allofficiallanguages(language) as 
(
 select language from city,countrylanguage where countrylanguage.countrycode = city.countrycode and isofficial = 'True'
 UNION 
 select language from allofficiallanguages)
select * from allofficiallanguages;