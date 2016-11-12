CREATE OR REPLACE PACKAGE PUNIT_TESTING IS
  PROCEDURE run_tests(package_name ALL_OBJECTS.object_name%TYPE, die_if_failed boolean DEFAULT true);
  PROCEDURE disable_test(reason string);
  PROCEDURE assert_equals(expected INT, actual INT);
END PUNIT_TESTING;
/
CREATE OR REPLACE PACKAGE BODY PUNIT_TESTING IS
  assertion_error EXCEPTION;
  PRAGMA EXCEPTION_INIT(assertion_error, -20101);
  disabled_test EXCEPTION;
  PRAGMA EXCEPTION_INIT(disabled_test, -20102);

  PROCEDURE disable_test(reason string) IS
    BEGIN
      raise_application_error(-20102, reason);
    END disable_test;

  PROCEDURE assert_equals(expected INT, actual INT) IS
      owner_name ALL_OBJECTS.owner%TYPE;
      caller_name ALL_SOURCE.name%TYPE;
      line_number ALL_SOURCE.line%TYPE;
      caller_type ALL_SOURCE.type%TYPE;
      source_line ALL_SOURCE.text%TYPE;
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

  PROCEDURE run_tests(package_name ALL_OBJECTS.object_name%TYPE, die_if_failed boolean) IS
      start_time timestamp  := systimestamp;
      testee VARCHAR2(61);
      run int := 0;
      passed int := 0;
      failed int := 0;
      errored int := 0;
      skipped int := 0;
    BEGIN
      DBMS_OUTPUT.put_line('Running ' || package_name);
      FOR p IN (SELECT procedure_name
          FROM ALL_PROCEDURES
          WHERE object_name = package_name
          AND procedure_name LIKE 'TEST_%')
        LOOP
          run := run + 1;
          testee := package_name || '.' || p.procedure_name;
          BEGIN
            EXECUTE IMMEDIATE 'BEGIN ' || testee || '; END;';
            passed := passed + 1;
            DBMS_OUTPUT.put_line(unistr('\2713') || ' ' || testee || ' passed.');
          EXCEPTION
            WHEN disabled_test THEN
              skipped := skipped + 1;
              DBMS_OUTPUT.put_line('- ' || testee || ' skipped: ' || SQLERRM);
            WHEN assertion_error THEN
              IF (die_if_failed) THEN
                RAISE;
              END IF;
              failed := failed + 1;
              DBMS_OUTPUT.put_line(unistr('\2717') || ' ' || testee || ' failed: ' || SQLERRM);
            WHEN OTHERS THEN
              IF (die_if_failed) THEN
                RAISE;
              END IF;
              errored := errored + 1;
              DBMS_OUTPUT.put_line('? ' || testee || ' errored: ' || SQLERRM);
              -- Cannot use the superior UTL_CALL_STACK package: 12c vs 11c
              -- Not put_line: backtrace already ends in a newline
              DBMS_OUTPUT.put(DBMS_UTILITY.format_error_backtrace());
          END;
        END LOOP;

        DBMS_OUTPUT.put_line('Tests run: ' || run || ', Failures: ' || failed || ', Errors: ' || errored || ', Skipped: ' || skipped || ', Time elapsed: ' || to_hundreds_of_second(systimestamp, start_time) || ' sec - in ' || package_name);
      END run_tests;
END PUNIT_TESTING;
/
