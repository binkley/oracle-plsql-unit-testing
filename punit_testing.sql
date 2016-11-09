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

  FUNCTION to_hundreds_of_second(newer timestamp, older timestamp)
    RETURN string IS
      diff number;
    BEGIN
        SELECT (extract(second from newer) - extract(second from older)) * 1000 ms
          INTO diff
          FROM DUAL;
        RETURN to_char(diff / 100, 'FM990.00');
    END to_hundreds_of_second;

  PROCEDURE run_tests(package_name string) IS
      start_time timestamp  := systimestamp;
      run int := 0;
      passed int := 0;
      failed int := 0;
      errored int := 0;
      skipped int := 0;
    BEGIN
      dbms_output.put_line('Running ' || package_name);
      FOR proc IN (SELECT procedure_name
          FROM all_procedures
          WHERE object_name = package_name
          AND procedure_name LIKE 'TEST_%')
        LOOP
          run := run + 1;
          BEGIN
            EXECUTE IMMEDIATE 'BEGIN ' || package_name || '.' || proc.PROCEDURE_NAME || '; END;';
            passed := passed + 1;
            dbms_output.put_line(unistr('\2611') || ' ' || proc.PROCEDURE_NAME || ' passed.');
          EXCEPTION
            WHEN assertion_error THEN
              failed := failed + 1;
              dbms_output.put_line(unistr('\2612') || ' ' || proc.PROCEDURE_NAME || ' failed: '|| SQLERRM);
            WHEN OTHERS THEN
              errored := errored + 1;
              dbms_output.put_line(unistr('\2613') || ' ' || proc.PROCEDURE_NAME || ' errored: '|| SQLERRM);
              dbms_output.put_line(dbms_utility.FORMAT_ERROR_BACKTRACE());
          END;
        END LOOP;
        dbms_output.put_line('Tests run: ' || run || ', Failures: ' || failed || ', Errors: ' || errored || ', Skipped: ' || skipped || ', Time elapsed: ' || to_hundreds_of_second(systimestamp, start_time) || ' sec - in ' || package_name);
      END run_tests;
END PUNIT_TESTING;
/
