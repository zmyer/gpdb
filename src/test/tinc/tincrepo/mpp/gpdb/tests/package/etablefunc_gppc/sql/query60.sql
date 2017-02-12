    -- create describe (callback) function
    -- both input and output type must be internal
    CREATE OR REPLACE FUNCTION project_desc(internal)
    RETURNS internal
    AS '$libdir/tabfunc_gppc_demo', 'project_describe'
    LANGUAGE C;

    -- explicit return type not suitable for dynamic type resolution
    CREATE FUNCTION x() returns int
      AS '$libdir/tabfunc_gppc_demo', 'project'
      LANGUAGE C 
      WITH (describe = project_desc);
    -- ERROR:  DESCRIBE only supported for functions returning "record"

    -- explicit return type (setof) not suitable for dynamic type resolution
    CREATE FUNCTION x() returns setof int
      AS '$libdir/tabfunc_gppc_demo', 'project'
      LANGUAGE C 
      WITH (describe = project_desc);
    -- ERROR:  DESCRIBE only supported for functions returning "record"

    -- explicit return type (TABLE) not suitable for dynamic type resolution
    CREATE FUNCTION x() returns TABLE(id integer, "time" timestamp, sessionnum integer)
      AS '$libdir/tabfunc_gppc_demo', 'project'
      LANGUAGE C 
      WITH (describe = project_desc);
    -- ERROR:  DESCRIBE is not supported for functions that return TABLE

    -- explicit return type (OUT PARAMS) not suitable for dynamic type resolution
    CREATE FUNCTION x(OUT id integer, OUT "time" timestamp, OUT sessionnum integer)
      AS '$libdir/tabfunc_gppc_demo', 'project'
      LANGUAGE C 
      WITH (describe = project_desc);
    -- ERROR:  DESCRIBE is not supported for functions with OUT parameters
