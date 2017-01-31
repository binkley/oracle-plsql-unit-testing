CREATE OR REPLACE PACKAGE SAMPLE_TEST IS
    PROCEDURE setup;
    PROCEDURE teardown;
    PROCEDURE setup_test;
    PROCEDURE teardown_test;
    PROCEDURE test_two_equals_two;
    PROCEDURE test_null_is_null;
    PROCEDURE test_not_null_is_not_null;
END SAMPLE_TEST;
/

CREATE OR REPLACE PACKAGE BODY SAMPLE_TEST IS

    PROCEDURE setup IS
    BEGIN
		DBMS_OUTPUT.put_line('SETUP got executed.');
    END setup;

    PROCEDURE teardown IS
    BEGIN
		DBMS_OUTPUT.put_line('TEARDOWN got executed.');
    END teardown;

    PROCEDURE setup_test IS
    BEGIN
        DBMS_OUTPUT.put_line('SETUP TEST got executed');
    END setup_test;

    PROCEDURE teardown_test IS
    BEGIN
        DBMS_OUTPUT.put_line('TEARDOWN TEST got executed');
    END teardown_test;

    PROCEDURE test_two_equals_two IS
    BEGIN
        ASSERT.equals(2, 2);
    END test_two_equals_two;

    PROCEDURE test_null_is_null IS
        null_varchar VARCHAR2(10) := NULL;
    BEGIN
        ASSERT.is_null(null_varchar);
    END test_null_is_null;

    PROCEDURE test_not_null_is_not_null IS
    BEGIN
        ASSERT.is_not_null('not null');
    END test_not_null_is_not_null;

END SAMPLE_TEST;
/

BEGIN
    PUNIT_RUNNER.run_tests('SAMPLE_TEST', raise_on_fail => false);
END;
/