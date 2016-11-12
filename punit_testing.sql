DROP TYPE t_punit_test_results;
CREATE OR REPLACE TYPE t_punit_test_result AS OBJECT (
  testee VARCHAR2(61),
  test_result INT,
  exception_code NUMBER,
  cause VARCHAR2(512),
  trace VARCHAR2(5000));
CREATE TYPE t_punit_test_results AS TABLE OF t_punit_test_result;
/
CREATE OR REPLACE PACKAGE PUNIT_TESTING IS
  PROCEDURE run_tests(package_name STRING, die_if_failed BOOLEAN DEFAULT true);
  FUNCTION do_run_tests(package_name string, test_name_pattern string)
    RETURN t_punit_test_results PIPELINED;
  PROCEDURE disable_test(reason STRING);
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

  FUNCTION do_run_tests(package_name string, test_name_pattern string)
    RETURN t_punit_test_results PIPELINED IS
      testee VARCHAR2(61);
      test_result t_punit_test_result := t_punit_test_result(NULL, NULL, 0, NULL, NULL);
    BEGIN
      FOR p IN (SELECT procedure_name
          FROM ALL_PROCEDURES
          WHERE object_name = package_name
          AND procedure_name LIKE test_name_pattern)
        LOOP
          testee := package_name || '.' || p.procedure_name;
          BEGIN
            EXECUTE IMMEDIATE 'BEGIN ' || testee || '; END;';
            test_result := t_punit_test_result(testee, 0, 0, NULL, NULL);
          EXCEPTION
            WHEN disabled_test THEN
              test_result := t_punit_test_result(testee, 1, SQLCODE, SQLERRM, NULL);
            WHEN assertion_error THEN
              test_result := t_punit_test_result(testee, 2, SQLCODE, SQLERRM, NULL);
            WHEN OTHERS THEN
              test_result := t_punit_test_result(testee, 3, SQLCODE, SQLERRM,
                  DBMS_UTILITY.format_error_backtrace());
          END;
          PIPE ROW(test_result);
        END LOOP;
        RETURN;
    END do_run_tests;

  PROCEDURE run_tests(package_name string, die_if_failed boolean) IS
      start_time timestamp  := systimestamp;
      run int := 0;
      passed int := 0;
      failed int := 0;
      errored int := 0;
      skipped int := 0;
    BEGIN
      DBMS_OUTPUT.put_line('Running ' || package_name);

      FOR t IN (SELECT * FROM TABLE(do_run_tests(package_name, 'TEST_%')))
        LOOP
          run := run + 1;
          CASE t.test_result
            WHEN 0 THEN
              passed := passed + 1;
              DBMS_OUTPUT.put_line(unistr('\2713') || ' ' || t.testee || ' passed.');
            WHEN 1 THEN
              skipped := skipped + 1;
              DBMS_OUTPUT.put_line('- ' || t.testee || ' skipped: ' || t.cause);
            WHEN 2 THEN
              IF (die_if_failed) THEN
                raise_application_error(t.exception_code, t.cause);
              END IF;
              failed := failed + 1;
              DBMS_OUTPUT.put_line(unistr('\2717') || ' ' || t.testee || ' failed: ' || t.cause);
            WHEN 3 THEN
              IF (die_if_failed) THEN
                raise_application_error(t.exception_code, t.cause);
              END IF;
              errored := errored + 1;
              DBMS_OUTPUT.put_line('? ' || t.testee || ' errored: ' || t.cause);
              DBMS_OUTPUT.put_line(DBMS_UTILITY.format_error_backtrace());
          END CASE;
        END LOOP;

        DBMS_OUTPUT.put_line('Tests run: ' || run || ', Failures: ' || failed || ', Errors: ' || errored || ', Skipped: ' || skipped || ', Time elapsed: ' || to_hundreds_of_second(systimestamp, start_time) || ' sec - in ' || package_name);
      END run_tests;
END PUNIT_TESTING;
/
