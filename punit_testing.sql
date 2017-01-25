CREATE OR REPLACE PACKAGE PUNIT_TESTING IS
	TYPE suite IS TABLE OF ALL_OBJECTS.object_name%TYPE;

	PROCEDURE run_tests(package_name ALL_OBJECTS.object_name%TYPE, raise_on_fail BOOLEAN DEFAULT true);
	PROCEDURE run_suite(suite_of_tests in suite, raise_on_fail BOOLEAN DEFAULT true);
    PROCEDURE disable_test(reason string);
END PUNIT_TESTING;
/

CREATE OR REPLACE PACKAGE BODY PUNIT_TESTING IS
	TYPE result_type IS TABLE OF INT INDEX BY VARCHAR2(15);

    assertion_error EXCEPTION; PRAGMA EXCEPTION_INIT(assertion_error, -20101);
    disabled_test EXCEPTION; PRAGMA EXCEPTION_INIT(disabled_test, -20102);
    fixture_exception EXCEPTION; PRAGMA EXCEPTION_INIT(fixture_exception, -20103);

    PROCEDURE disable_test(reason string) IS
	BEGIN
        raise_application_error(-20102, reason);
    END disable_test;

    FUNCTION to_hundreds_of_second(newer timestamp, older timestamp) RETURN string IS
		diff NUMBER;
    BEGIN
      	SELECT (extract(second from newer) - extract(second from older)) * 1000 ms INTO diff FROM DUAL;

      	RETURN to_char(diff / 100, 'FM990.00');
    END to_hundreds_of_second;

	PROCEDURE print_results(results result_type, is_suite BOOLEAN) IS
	BEGIN
		DBMS_OUTPUT.put_line(chr(13));
		IF is_suite THEN
			DBMS_OUTPUT.put_line('Suite Results');
			DBMS_OUTPUT.put_line('--------------------------------------------------------');
		END IF;
		DBMS_OUTPUT.put_line('Tests Run: ' || results('run') || ', '
								|| 'Passed: ' || results('passed') || ', '
								|| 'Failures: ' || results('failed') || ', '
								|| 'Errors: ' || results('errored') || ', '
								|| 'Skipped: ' || results('skipped'));
	END print_results;

	PROCEDURE run_fixture(package_name ALL_OBJECTS.object_name%TYPE, fixture_type VARCHAR2) IS
		fixture_name ALL_PROCEDURES.procedure_name%TYPE;
		fixture_procedure VARCHAR(100);
	BEGIN
		BEGIN
			SELECT procedure_name INTO fixture_name FROM ALL_PROCEDURES WHERE object_name = package_name AND procedure_name = fixture_type;
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
		END;

		fixture_procedure := package_name || '.' || fixture_name;
		DBMS_OUTPUT.put_line('Running ' || fixture_procedure);
		BEGIN
			EXECUTE IMMEDIATE 'BEGIN ' || fixture_procedure || '; END;';
			DBMS_OUTPUT.put_line(unistr('\2713') || ' ' || fixture_procedure || ' finished running.');
		EXCEPTION
		WHEN OTHERS THEN
			raise_application_error(-20103, fixture_type || ' failed to complete');
		END;
	END run_fixture;

	FUNCTION run_test(package_name ALL_OBJECTS.object_name%TYPE, procedure_name ALL_PROCEDURES.procedure_name%TYPE, raise_on_fail BOOLEAN) RETURN VARCHAR2 IS
		testee VARCHAR2(61);
	BEGIN
		testee := package_name || '.' || procedure_name;
		BEGIN
			EXECUTE IMMEDIATE 'BEGIN ' || testee || '; END;';
			DBMS_OUTPUT.put_line(unistr('\2713') || ' ' || testee || ' passed.');
			RETURN 'passed';
		EXCEPTION
		WHEN disabled_test THEN
			DBMS_OUTPUT.put_line('- ' || testee || ' skipped: ' || SQLERRM);
			RETURN 'skipped';
		WHEN assertion_error THEN
			IF (raise_on_fail) THEN
				RAISE;
			END IF;
			DBMS_OUTPUT.put_line(unistr('\2717') || ' ' || testee || ' failed: ' || SQLERRM);
			RETURN 'failed';
		WHEN OTHERS THEN
			IF (raise_on_fail) THEN
				RAISE;
			END IF;
			DBMS_OUTPUT.put_line('? ' || testee || ' errored: ' || SQLERRM);
			-- Cannot use the superior UTL_CALL_STACK package: 12c vs 11c
			-- Not put_line: backtrace already ends in a newline
			DBMS_OUTPUT.put(DBMS_UTILITY.format_error_backtrace());
			RETURN 'errored';
		END;
	END run_test;

    FUNCTION run_tests(package_name ALL_OBJECTS.object_name%TYPE, raise_on_fail BOOLEAN) RETURN result_type IS
		results result_type;
		test_result VARCHAR2(10);

		start_time TIMESTAMP := systimestamp;
    BEGIN
		results('run') := 0;
		results('passed') := 0;
		results('failed') := 0;
		results('errored') := 0;
		results('skipped') := 0;
		
		DBMS_OUTPUT.put_line(chr(13));
		run_fixture(package_name, 'SETUP');

		DBMS_OUTPUT.put_line('Running ' || package_name);
		FOR p IN (SELECT procedure_name FROM ALL_PROCEDURES WHERE object_name = package_name AND procedure_name LIKE 'TEST_%') LOOP
			results('run') := results('run') + 1;
			test_result := run_test(package_name, p.procedure_name, raise_on_fail);
			results(test_result) := results(test_result) + 1;
		END LOOP;
		run_fixture(package_name, 'TEARDOWN');
		
		print_results(results, false);
		DBMS_OUTPUT.put_line('Elapsed Time: ' || to_hundreds_of_second(systimestamp, start_time) || ' sec - in ' || package_name);

		RETURN results;
    END run_tests;

	PROCEDURE run_tests(package_name ALL_OBJECTS.object_name%TYPE, raise_on_fail BOOLEAN) IS
		test_results result_type;
	BEGIN
		test_results := run_tests(package_name, raise_on_fail);
	END run_tests;

	PROCEDURE run_suite(suite_of_tests in suite, raise_on_fail BOOLEAN) IS
		suite_results result_type;
		test_results result_type;

		start_time TIMESTAMP := systimestamp;
	BEGIN
		suite_results('run') := 0;
		suite_results('passed') := 0;
		suite_results('failed') := 0;
		suite_results('errored') := 0;
		suite_results('skipped') := 0;

    	FOR i IN suite_of_tests.FIRST .. suite_of_tests.LAST LOOP
			test_results := run_tests(suite_of_tests(i), raise_on_fail);
			suite_results('run') := suite_results('run') + test_results('run');
			suite_results('passed') := suite_results('passed') + test_results('passed');
			suite_results('failed') := suite_results('failed') + test_results('failed');
			suite_results('errored') := suite_results('errored') + test_results('errored');
			suite_results('skipped') := suite_results('skipped') + test_results('skipped');
    	END LOOP;

		print_results(suite_results, true);
		DBMS_OUTPUT.put_line('Elapsed Time: ' || to_hundreds_of_second(systimestamp, start_time));
	END run_suite;

END PUNIT_TESTING;
/
