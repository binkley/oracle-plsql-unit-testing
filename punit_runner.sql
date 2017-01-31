CREATE OR REPLACE PACKAGE PUNIT_RUNNER IS
	TYPE suite IS TABLE OF ALL_OBJECTS.object_name%TYPE;

	PROCEDURE run_tests(package_name ALL_OBJECTS.object_name%TYPE, raise_on_fail BOOLEAN DEFAULT true);
	PROCEDURE run_suite(suite_of_tests in suite, raise_on_fail BOOLEAN DEFAULT true);
END PUNIT_RUNNER;
/

CREATE OR REPLACE PACKAGE BODY PUNIT_RUNNER IS
	fixture_exception EXCEPTION; PRAGMA EXCEPTION_INIT(fixture_exception, -20103);

	TYPE result_type IS TABLE OF INT INDEX BY VARCHAR2(15);

    FUNCTION to_hundreds_of_second(newer timestamp, older timestamp) RETURN string IS
		diff NUMBER;
    BEGIN
      	SELECT (extract(second from newer) - extract(second from older)) * 1000 ms INTO diff FROM DUAL;

      	RETURN to_char(diff / 100, 'FM990.00');
    END to_hundreds_of_second;

	PROCEDURE initialize_results(results OUT result_type) IS
	BEGIN
		results('run') := 0;
		results('passed') := 0;
		results('failed') := 0;
		results('errored') := 0;
		results('skipped') := 0;
	END initialize_results;

	PROCEDURE print_results(results result_type) IS
	BEGIN
		DBMS_OUTPUT.put_line(chr(13));
		DBMS_OUTPUT.put_line('Run: ' || results('run') || ', '
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
		BEGIN
			EXECUTE IMMEDIATE 'BEGIN ' || fixture_procedure || '; END;';
		EXCEPTION
		WHEN OTHERS THEN
			raise_application_error(-20103, fixture_type || ' failed to complete');
		END;
	END run_fixture;

    FUNCTION run_tests(package_name ALL_OBJECTS.object_name%TYPE, raise_on_fail BOOLEAN) RETURN result_type IS
		results result_type;
		test_result VARCHAR2(10);

		start_time TIMESTAMP := systimestamp;
    BEGIN
		initialize_results(results);
		
		DBMS_OUTPUT.put_line(chr(13));
		run_fixture(package_name, 'SETUP');

		DBMS_OUTPUT.put_line('Running ' || package_name);
		FOR p IN (SELECT procedure_name FROM ALL_PROCEDURES WHERE object_name = package_name AND procedure_name LIKE 'TEST_%') LOOP
			run_fixture(package_name, 'SETUP_TEST');
			results('run') := results('run') + 1;
			test_result := PUNIT_TEST.run_test(package_name, p.procedure_name, raise_on_fail);
			results(test_result) := results(test_result) + 1;
			run_fixture(package_name, 'TEARDOWN_TEST');
		END LOOP;
		run_fixture(package_name, 'TEARDOWN');
		
		print_results(results);
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
		initialize_results(suite_results);

    	FOR i IN suite_of_tests.FIRST .. suite_of_tests.LAST LOOP
			test_results := run_tests(suite_of_tests(i), raise_on_fail);
			suite_results('run') := suite_results('run') + test_results('run');
			suite_results('passed') := suite_results('passed') + test_results('passed');
			suite_results('failed') := suite_results('failed') + test_results('failed');
			suite_results('errored') := suite_results('errored') + test_results('errored');
			suite_results('skipped') := suite_results('skipped') + test_results('skipped');
    	END LOOP;
		
		print_results(suite_results);
		DBMS_OUTPUT.put_line('Elapsed Time: ' || to_hundreds_of_second(systimestamp, start_time));
	END run_suite;

END PUNIT_RUNNER;
/
