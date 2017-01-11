CREATE OR REPLACE PACKAGE SAMPLE_TEST IS
    PROCEDURE setup;
    PROCEDURE teardown;
    PROCEDURE test_two_equals_two;
    PROCEDURE test_null_is_null;
END SAMPLE_TEST;
/

CREATE OR REPLACE PACKAGE BODY SAMPLE_TEST IS

    PROCEDURE setup IS
    BEGIN
		DBMS_OUTPUT.put_line('setup got executed.');
    END setup;

    PROCEDURE teardown IS
    BEGIN
		DBMS_OUTPUT.put_line('teardown got executed.');
    END teardown;

    PROCEDURE test_two_equals_two IS
    BEGIN
        ASSERT.equals(2, 2);
    END test_two_equals_two;

    PROCEDURE test_null_is_null IS
    BEGIN
        ASSERT.is_null(NULL);
    END test_null_is_null;

END SAMPLE_TEST;
/

BEGIN
    PUNIT_TESTING.run_tests('SAMPLE_TEST', raise_on_fail => false);
END;
/