    -- create describe (callback) function
    -- both input and output type must be internal
    CREATE OR REPLACE FUNCTION project_desc(internal)
    RETURNS internal
    AS '$libdir/tabfunc_gppc_demo', 'project_describe'
    LANGUAGE C;

    -- create dynamic return type (drt) table function
    -- using the callback function
    -- the return type must be defined as set of record
    CREATE OR REPLACE FUNCTION project(anytable, integer)
    RETURNS setof record
    AS '$libdir/tabfunc_gppc_demo', 'project'
    LANGUAGE C
    WITH (describe = project_desc);

   -- DRT table function cannot be used to create view
    CREATE VIEW project_v
    AS SELECT * 
    FROM project ( TABLE (SELECT * FROM history ORDER BY id, time SCATTER BY id ), 1);
    -- ERROR:  CREATE VIEW statements cannot include calls to dynamically typed function

    CREATE VIEW project_v
    AS SELECT * FROM (SELECT *
    FROM project ( TABLE (SELECT * FROM history ORDER BY id, time SCATTER BY id ), 1) as project_alias) as project_alias2;
    -- ERROR:  CREATE VIEW statements cannot include calls to dynamically typed function

-- An existing function that has views defined over it can not be allowed to
-- be altered to have a describe function for similar reasons outlined above.
    -- Create table function project_plain
    -- WITHOUT using the callback function
    CREATE OR REPLACE FUNCTION project_plain (anytable, integer) 
    RETURNS setof record
    AS '$libdir/tabfunc_gppc_demo', 'project' 
    LANGUAGE C;

    -- Create a view using table function project_plain
    -- which should be allowed
    CREATE VIEW project_plain_v
    AS SELECT * 
    FROM project_plain ( TABLE (SELECT * FROM history ORDER BY id, time SCATTER BY id ), 1)
    AS project(id integer, "time" timestamp, sessionnum integer);

    -- Now try to replace table func project_plain with one 
    -- actually is Dynamic Return Type table func
    -- i.e. using callback function        
    CREATE OR REPLACE FUNCTION project_plain(anytable, integer) 
    RETURNS setof record
    AS '$libdir/tabfunc_gppc_demo', 'project' 
    LANGUAGE C
    WITH (describe = project_desc);
    -- ERROR:  cannot add DESCRIBE callback to function used in view(s)

    DROP VIEW project_plain_v;
