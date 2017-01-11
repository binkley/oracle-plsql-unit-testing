CREATE OR REPLACE PACKAGE PUNIT_TESTING IS
    PROCEDURE run_tests(package_name ALL_OBJECTS.object_name%TYPE, raise_on_fail boolean DEFAULT true);
    PROCEDURE disable_test(reason string);
END PUNIT_TESTING;
/

CREATE OR REPLACE PACKAGE BODY PUNIT_TESTING IS
    assertion_error EXCEPTION;
    PRAGMA EXCEPTION_INIT(assertion_error, -20101);
    disabled_test EXCEPTION;
    PRAGMA EXCEPTION_INIT(disabled_test, -20102);
    fixture_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(fixture_exception, -20103);

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

    PROCEDURE run_tests(package_name ALL_OBJECTS.object_name%TYPE, raise_on_fail boolean) IS
      	start_time TIMESTAMP := systimestamp;
      	testee VARCHAR2(61);
      	run INT := 0;
      	passed INT := 0;
      	failed INT := 0;
      	errored INT := 0;
      	skipped INT := 0;
    BEGIN
	  	run_fixture(package_name, 'SETUP');
      	DBMS_OUTPUT.put_line('Running ' || package_name);
      	FOR p IN (SELECT procedure_name FROM ALL_PROCEDURES WHERE object_name = package_name AND procedure_name LIKE 'TEST_%') LOOP
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
				IF (raise_on_fail) THEN
              		RAISE;
            	END IF;
            	failed := failed + 1;
            	DBMS_OUTPUT.put_line(unistr('\2717') || ' ' || testee || ' failed: ' || SQLERRM);
          	WHEN OTHERS THEN
    			IF (raise_on_fail) THEN
					RAISE;
            	END IF;
            	errored := errored + 1;
            	DBMS_OUTPUT.put_line('? ' || testee || ' errored: ' || SQLERRM);
            	-- Cannot use the superior UTL_CALL_STACK package: 12c vs 11c
            	-- Not put_line: backtrace already ends in a newline
            	DBMS_OUTPUT.put(DBMS_UTILITY.format_error_backtrace());
        	END;
		END LOOP;
		run_fixture(package_name, 'TEARDOWN');

      	DBMS_OUTPUT.put_line('Tests run: ' || run || ', Failures: ' || failed || ', Errors: ' || errored || ', Skipped: ' || skipped || ', Time elapsed: ' || to_hundreds_of_second(systimestamp, start_time) || ' sec - in ' || package_name);
    END run_tests;

END PUNIT_TESTING;
/
