CREATE OR REPLACE PACKAGE PUNIT_TEST IS
	FUNCTION run_test(package_name ALL_OBJECTS.object_name%TYPE, procedure_name ALL_PROCEDURES.procedure_name%TYPE, raise_on_fail BOOLEAN) RETURN VARCHAR2;
    PROCEDURE disable_test(reason string);
END PUNIT_TEST;
/

CREATE OR REPLACE PACKAGE BODY PUNIT_TEST IS
    assertion_error EXCEPTION; PRAGMA EXCEPTION_INIT(assertion_error, -20101);
    disabled_test EXCEPTION; PRAGMA EXCEPTION_INIT(disabled_test, -20102);
    fixture_exception EXCEPTION; PRAGMA EXCEPTION_INIT(fixture_exception, -20103);

    PROCEDURE disable_test(reason string) IS
	BEGIN
        raise_application_error(-20102, reason);
    END disable_test;

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

END PUNIT_TEST;
/
