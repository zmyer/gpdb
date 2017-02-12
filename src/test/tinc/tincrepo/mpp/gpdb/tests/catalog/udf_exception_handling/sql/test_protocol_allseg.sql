CREATE OR REPLACE FUNCTION test_protocol_allseg(mid int, mshop int , mgender character, mname varchar, msalary int, marg int ) RETURNS VOID AS
$$
DECLARE tfactor int default 0;
BEGIN
  BEGIN
  DROP TABLE IF EXISTS employees;

  CREATE TABLE employees (
  id int NOT NULL PRIMARY KEY,
  shop_id int NOT NULL ,
  gender character NOT NULL,
  name varchar(32) NOT NULL,
  salary int  CHECK(salary > 0), 
  factor int 
  );  
  END;
  BEGIN
  DROP TABLE IF EXISTS shops;

  CREATE TABLE shops (
  id serial PRIMARY KEY,
  shop varchar(32)
  );  

  INSERT INTO shops (shop)
  VALUES ('san francisco'), ('New York');
  END;
 BEGIN
  BEGIN
    IF EXISTS (select 1 from employees where id = mid) THEN
        RAISE EXCEPTION 'Duplicate employee id';
    ELSE
         IF NOT (mshop between 1 AND 2) THEN
            RAISE EXCEPTION 'Invalid shop id' ;
        END IF;
    END IF;
    IF (tfactor = 0) THEN
        select * into tfactor from test_excep(marg); 
       
    END IF;
    BEGIN
        INSERT INTO employees (id,shop_id, gender, name, salary, factor)
        VALUES (mid,mshop,mgender, mname, msalary, tfactor);    
    EXCEPTION
            WHEN OTHERS THEN
            BEGIN
                RAISE NOTICE 'catching the exception ...3';
            END;
    END;
   EXCEPTION
       WHEN OTHERS THEN
          RAISE NOTICE 'catching the exception ...2';
   END;
 EXCEPTION
     WHEN OTHERS THEN
          RAISE NOTICE 'catching the exception ...1';
 END;

END;
$$
LANGUAGE plpgsql;
