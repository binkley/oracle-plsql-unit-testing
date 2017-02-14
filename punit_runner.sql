CREATE OR REPLACE PACKAGE PUNIT_RUNNER IS
	TYPE suite IS TABLE OF ALL_OBJECTS.object_name%TYPE;

	PROCEDURE run_tests(package_name ALL_OBJECTS.object_name%TYPE, raise_on_fail BOOLEAN DEFAULT true);
	PROCEDURE run_suite(suite_of_tests in suite, raise_on_fail BOOLEAN DEFAULT true);
END PUNIT_RUNNER;
/

CREATE OR REPLACE PACKAGE BODY PUNIT_RUNNER IS

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
	
	FUNCTION get_results_summary(results result_type) RETURN VARCHAR2 IS
		results_summary VARCHAR2(4000);
	BEGIN
		results_summary := 'Run: ' || results('run') || ', '
								|| 'Passed: ' || results('passed') || ', '
								|| 'Failures: ' || results('failed') || ', '
								|| 'Errors: ' || results('errored') || ', '
								|| 'Skipped: ' || results('skipped');
    return results_summary;
	END get_results_summary;

	PROCEDURE print_results(results result_type) IS
	BEGIN
		DBMS_OUTPUT.put_line(chr(13) || get_results_summary(results));
	END print_results;

    FUNCTION run_tests(package_name ALL_OBJECTS.object_name%TYPE, raise_on_fail BOOLEAN) RETURN result_type 
    IS
      results result_type;
      test_result VARCHAR2(10);
      results_summary VARCHAR2(4000);
      start_time TIMESTAMP := systimestamp;

	  package_fixture_pass BOOLEAN := FALSE;
	  test_fixture_pass BOOLEAN := FALSE;
    BEGIN
		initialize_results(results);
		
		DBMS_OUTPUT.put_line(chr(13));
		package_fixture_pass := PUNIT_FIXTURE.setup_package(package_name);
		IF (package_fixture_pass) THEN
			DBMS_OUTPUT.put_line('Running ' || package_name);
			FOR p IN (SELECT procedure_name FROM ALL_PROCEDURES WHERE object_name = package_name AND procedure_name LIKE 'TEST_%') LOOP
        		test_fixture_pass := PUNIT_FIXTURE.setup(package_name);
				IF (test_fixture_pass) THEN
        			results('run') := results('run') + 1;
        			test_result := PUNIT_TEST.run_test(package_name, p.procedure_name, raise_on_fail);
        			results(test_result) := results(test_result) + 1;
				END IF;
        		PUNIT_FIXTURE.teardown(package_name);
      		END LOOP;
		END IF;
      	PUNIT_FIXTURE.teardown_package(package_name);
		
		results_summary := get_results_summary(results);
		DBMS_OUTPUT.put_line('results_summary = ' || results_summary); 
      	IF (results('run') != results('passed')) THEN
        	raise_application_error(-20101,	results_summary);   
      	END IF;
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
