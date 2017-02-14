BEGIN
    DBMS_OUTPUT.put_line('installing oracle plsql unit testing library');
    @punit_fixture.sql;
    @punit_test.sql;
    @punit_runner.sql;
    @assert.sql;
END;
/

EXIT;