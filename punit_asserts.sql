CREATE OR REPLACE PACKAGE PUNIT_ASSERTS IS
    PROCEDURE assert_equals(expected VARCHAR2, actual VARCHAR2);
    PROCEDURE assert_equals(expected INT, actual INT);
    PROCEDURE assert_null(actual INT);
END PUNIT_ASSERTS;
/

CREATE OR REPLACE PACKAGE BODY PUNIT_ASSERTS IS

    PROCEDURE assert_equals(expected INT, actual INT) IS
    BEGIN
        IF (expected = actual) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'expected: ' || expected || '; actual: ' || actual );
    END assert_equals;
    
    PROCEDURE assert_equals(expected VARCHAR2, actual VARCHAR2) IS
    BEGIN
        IF (expected = actual) THEN
            RETURN;
        END IF;
      
        raise_application_error(-20101, 'expected: ' || expected || '; actual: ' || actual );
    END assert_equals;

    PROCEDURE assert_null(actual INT) IS 
    BEGIN
        IF (actual IS NULL) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'expected: NULL; actual: ' || actual );
    END assert_null;

END PUNIT_ASSERTS;
/