CREATE OR REPLACE PACKAGE PUNIT_FIXTURE IS
    PROCEDURE setup(package_name ALL_OBJECTS.object_name%TYPE);
    PROCEDURE teardown(package_name ALL_OBJECTS.object_name%TYPE);
    PROCEDURE setup_package(package_name ALL_OBJECTS.object_name%TYPE);
    PROCEDURE teardown_package(package_name ALL_OBJECTS.object_name%TYPE);
END PUNIT_FIXTURE;
/

CREATE OR REPLACE PACKAGE BODY PUNIT_FIXTURE IS

    fixture_exception EXCEPTION; PRAGMA EXCEPTION_INIT(fixture_exception, -20103);

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

    PROCEDURE setup(package_name ALL_OBJECTS.object_name%TYPE) IS
    BEGIN
        run_fixture(package_name, 'SETUP');
    END setup;

    PROCEDURE setup_package(package_name ALL_OBJECTS.object_name%TYPE) IS
    BEGIN
        run_fixture(package_name, 'SETUP_PACKAGE');
    END setup_package;

    PROCEDURE teardown(package_name ALL_OBJECTS.object_name%TYPE) IS
    BEGIN
        run_fixture(package_name, 'TEARDOWN');
    END teardown;

    PROCEDURE teardown_package(package_name ALL_OBJECTS.object_name%TYPE) IS
    BEGIN
        run_fixture(package_name, 'TEARDOWN_PACKAGE');
    END teardown_package;

END PUNIT_FIXTURE;
/