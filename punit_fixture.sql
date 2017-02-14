CREATE OR REPLACE PACKAGE PUNIT_FIXTURE IS
    FUNCTION setup(package_name ALL_OBJECTS.object_name%TYPE) RETURN BOOLEAN;
    PROCEDURE teardown(package_name ALL_OBJECTS.object_name%TYPE);
    FUNCTION setup_package(package_name ALL_OBJECTS.object_name%TYPE) RETURN BOOLEAN;
    PROCEDURE teardown_package(package_name ALL_OBJECTS.object_name%TYPE);
END PUNIT_FIXTURE;
/

CREATE OR REPLACE PACKAGE BODY PUNIT_FIXTURE IS

    FUNCTION run_fixture(package_name ALL_OBJECTS.object_name%TYPE, fixture_type VARCHAR2) RETURN BOOLEAN IS
		fixture_name ALL_PROCEDURES.procedure_name%TYPE;
		fixture_procedure VARCHAR(100);
	BEGIN
		BEGIN
			SELECT procedure_name INTO fixture_name FROM ALL_PROCEDURES WHERE object_name = package_name AND procedure_name = fixture_type;
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.put_line(fixture_type || ' not available. No need to run');
			RETURN TRUE;
		END;

		fixture_procedure := package_name || '.' || fixture_name;
		BEGIN
			EXECUTE IMMEDIATE 'BEGIN ' || fixture_procedure || '; END;';
		EXCEPTION
		WHEN OTHERS THEN
            DBMS_OUTPUT.put_line(fixture_type || ' failed to complete: ' || SQLCODE || SQLERRM);
            -- Cannot use the superior UTL_CALL_STACK package: 12c vs 11c
			-- Not put_line: backtrace already ends in a newline
            DBMS_OUTPUT.put(DBMS_UTILITY.format_error_backtrace());
            RETURN FALSE;
		END;
        RETURN TRUE;
	END run_fixture;

    FUNCTION setup(package_name ALL_OBJECTS.object_name%TYPE) RETURN BOOLEAN IS
        result BOOLEAN;
    BEGIN
        result := run_fixture(package_name, 'SETUP');
        RETURN result;
    END setup;

    FUNCTION setup_package(package_name ALL_OBJECTS.object_name%TYPE) RETURN BOOLEAN IS
        result BOOLEAN;
    BEGIN
        result := run_fixture(package_name, 'SETUP_PACKAGE');
        RETURN result;
    END setup_package;

    PROCEDURE teardown(package_name ALL_OBJECTS.object_name%TYPE) IS
        result BOOLEAN;
    BEGIN
        result := run_fixture(package_name, 'TEARDOWN');
    END teardown;

    PROCEDURE teardown_package(package_name ALL_OBJECTS.object_name%TYPE) IS
        result BOOLEAN;
    BEGIN
        result := run_fixture(package_name, 'TEARDOWN_PACKAGE');
    END teardown_package;

END PUNIT_FIXTURE;
/