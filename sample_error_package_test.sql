CREATE OR REPLACE PACKAGE SAMPLE_ERROR_PACKAGE_TEST IS
    PROCEDURE setup_package;
    PROCEDURE teardown_package;
    PROCEDURE test_will_not_run;
END SAMPLE_ERROR_PACKAGE_TEST;
/

CREATE OR REPLACE PACKAGE BODY SAMPLE_ERROR_PACKAGE_TEST IS

    PROCEDURE setup_package IS
    BEGIN
        DBMS_OUTPUT.put_line('SETUP PACKAGE errored out');
        raise_application_error(-20103, 'setup package erroring out' );
    END setup_package;

    PROCEDURE teardown_package IS
    BEGIN
        DBMS_OUTPUT.put_line('TEARDOWN PACKAGE got executed');
    END teardown_package;

    PROCEDURE test_will_not_run IS
    BEGIN
        ASSERT.equals(2, 2);
    END test_will_not_run;

END SAMPLE_ERROR_PACKAGE_TEST;
/

BEGIN
    PUNIT_RUNNER.run_tests('SAMPLE_ERROR_PACKAGE_TEST', raise_on_fail => false);
END;
/