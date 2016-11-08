CREATE OR REPLACE PACKAGE PUNIT_TESTING IS
  PROCEDURE run_tests(package_name STRING);
  PROCEDURE assert_equals(expected INT, actual INT);
END PUNIT_TESTING;
/
CREATE OR REPLACE PACKAGE BODY PUNIT_TESTING IS
  assertion_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(assertion_error, -20101);

  PROCEDURE assert_equals(expected INT, actual INT) IS
    BEGIN
      IF (expected = actual) THEN
        RETURN;
      END IF;
      raise_application_error(-20101, 'Expected: ' || expected || '; got: ' || actual);
    END assert_equals;

  PROCEDURE run_tests(package_name STRING) IS
      passed INT := 0;
      failed INT := 0;
      errored INT := 0;
    BEGIN
      FOR proc IN (SELECT procedure_name
          FROM all_procedures
          WHERE object_name = package_name
          AND procedure_name LIKE 'TEST_%')
        LOOP
          BEGIN
            EXECUTE IMMEDIATE 'BEGIN ' || package_name || '.' || proc.PROCEDURE_NAME || '; END;';
            passed := passed + 1;
            dbms_output.put_line(proc.PROCEDURE_NAME || ' passed.');
          EXCEPTION
            WHEN assertion_error THEN
              failed := failed + 1;
              dbms_output.put_line(proc.PROCEDURE_NAME || ' failed: ' || SQLERRM);
            WHEN OTHERS THEN
              errored := errored + 1;
              dbms_output.put_line(proc.PROCEDURE_NAME || ' errored: '|| SQLERRM);
              dbms_output.put_line(dbms_utility.FORMAT_ERROR_BACKTRACE());
            END;
          END LOOP;
          dbms_output.put_line('Summary: ' || passed || ' passed, ' || failed || ' failed, ' || errored || ' errored.');
      END run_tests;

  FUNCTION Do_It(value INT)
    RETURN INT IS
    BEGIN
      RETURN value;
    END Do_It;

  PROCEDURE TEST_Pass IS
    BEGIN
      assert_equals(2, Do_It(2));
    END TEST_Pass;

  PROCEDURE TEST_Fail IS
    BEGIN
      assert_equals(3, Do_It(2));
    END TEST_Fail;

  PROCEDURE TEST_Error IS
    BEGIN
      RAISE program_error;
    END TEST_Error;

END PUNIT_TESTING;
/
