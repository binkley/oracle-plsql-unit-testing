CREATE OR REPLACE PACKAGE SAMPLE_ERROR_SETUP_TEST IS
    PROCEDURE setup_package;
    PROCEDURE teardown_package;
    PROCEDURE setup;
    PROCEDURE teardown;
    PROCEDURE test_num_1_will_not_run;
    PROCEDURE test_num_2_will_not_run;
END SAMPLE_ERROR_SETUP_TEST;
/

CREATE OR REPLACE PACKAGE BODY SAMPLE_ERROR_SETUP_TEST IS

    PROCEDURE setup_package IS  
    BEGIN
        DBMS_OUTPUT.put_line('SETUP PACKAGE got executed');
    END setup_package;

    PROCEDURE teardown_package IS  
    BEGIN
        DBMS_OUTPUT.put_line('TEARDOWN PACKAGE got executed');
    END teardown_package;

    PROCEDURE setup IS
    BEGIN
        DBMS_OUTPUT.put_line('SETUP errored out');
        raise_application_error(-20103, 'setup erroring out' );
    END setup;

    PROCEDURE teardown IS
    BEGIN
        DBMS_OUTPUT.put_line('TEARDOWN got executed');
    END teardown;

    PROCEDURE test_num_1_will_not_run IS
    BEGIN
        ASSERT.equals(2, 2);
    END test_num_1_will_not_run;

    PROCEDURE test_num_2_will_not_run IS
    BEGIN
        ASSERT.equals(2, 2);
    END test_num_2_will_not_run;

END SAMPLE_ERROR_SETUP_TEST;
/

BEGIN
    PUNIT_RUNNER.run_tests('SAMPLE_ERROR_SETUP_TEST', raise_on_fail => false);
END;
/