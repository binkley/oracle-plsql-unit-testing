CREATE OR REPLACE PACKAGE PUNIT_TESTING IS
  PROCEDURE run_tests(package_name STRING);
  PROCEDURE assert_equals(expected INT, actual INT);
END PUNIT_TESTING;
/
CREATE OR REPLACE PACKAGE BODY PUNIT_TESTING IS
  assertion_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(assertion_error, -20101);

  PROCEDURE assert_equals(expected INT, actual INT) IS
      owner_name VARCHAR2(30);
      caller_name VARCHAR2(30);
      line_number NUMBER;
      caller_type VARCHAR2(100);
      source_line ALL_SOURCE.TEXT%TYPE;
    BEGIN
      IF (expected = actual) THEN
        RETURN;
      END IF;

      OWA_UTIL.who_called_me(owner_name, caller_name, line_number, caller_type);
      SELECT text
        INTO source_line
        FROM ALL_SOURCE
        WHERE name = caller_name
        AND type = 'PACKAGE BODY'
        AND line = line_number;

      raise_application_error(-20101, 'Expected: ' || expected || '; got: ' || actual || ' at ' || caller_name || '#l' || line_number || ': ' || trim(source_line));
    END assert_equals;

  PROCEDURE run_tests(package_name STRING) IS
      passed INT := 0;
      failed INT := 0;
      errored INT := 0;
    BEGIN
      dbms_output.put_line('Testing ' || package_name || '.');
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
              dbms_output.put_line(proc.PROCEDURE_NAME || ' failed: '|| SQLERRM);
            WHEN OTHERS THEN
              errored := errored + 1;
              dbms_output.put_line(proc.PROCEDURE_NAME || ' errored: '|| SQLERRM);
              dbms_output.put_line(dbms_utility.FORMAT_ERROR_BACKTRACE());
          END;
        END LOOP;
        dbms_output.put_line('Summary: ' || passed || ' passed, ' || failed || ' failed, ' || errored || ' errored.');
      END run_tests;
END PUNIT_TESTING;
/
