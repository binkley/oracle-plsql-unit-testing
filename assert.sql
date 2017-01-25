CREATE OR REPLACE PACKAGE ASSERT IS
    PROCEDURE equals(expected VARCHAR2, actual VARCHAR2);
    PROCEDURE equals(expected INT, actual INT);
    PROCEDURE not_equals(expected VARCHAR2, actual VARCHAR2);
    PROCEDURE not_equals(expected INT, actual INT);
    PROCEDURE is_null(actual VARCHAR2);
    PROCEDURE is_null(actual INT);
    PROCEDURE is_not_null(actual VARCHAR2);
    PROCEDURE is_not_null(actual INT);
    PROCEDURE is_true(actual BOOLEAN);
    PROCEDURE is_false(actual BOOLEAN);
    PROCEDURE less_than(expected INT, actual INT);
    PROCEDURE greater_than(expected INT, actual INT);
END ASSERT;
/

CREATE OR REPLACE PACKAGE BODY ASSERT IS

    PROCEDURE equals(expected INT, actual INT) IS
    BEGIN
        IF (expected = actual) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'expected: ' || expected || ' to equal actual: ' || actual );
    END equals;
    
    PROCEDURE equals(expected VARCHAR2, actual VARCHAR2) IS
    BEGIN
        IF (expected = actual) THEN
            RETURN;
        END IF;
      
        raise_application_error(-20101, 'expected: ' || expected || 'to equal actual: ' || actual );
    END equals;

    PROCEDURE not_equals(expected VARCHAR2, actual VARCHAR2) IS
    BEGIN
        IF (expected <> actual) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'expected: ' || expected || ' to not equal actual: ' || actual );
    END not_equals;

    PROCEDURE not_equals(expected INT, actual INT) IS
    BEGIN
        IF (expected <> actual) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'expected: ' || expected || ' to not equal actual: ' || actual );
    END not_equals;

    PROCEDURE is_null(actual INT) IS 
    BEGIN
        IF (actual IS NULL) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'actual: ' || actual || ' expected to be null');
    END is_null;

    PROCEDURE is_null(actual VARCHAR2) IS 
    BEGIN
        IF (actual IS NULL) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'actual: ' || actual || ' expected to be null');
    END is_null;

    PROCEDURE is_not_null(actual INT) IS
    BEGIN
        IF (actual IS NOT NULL) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'actual: ' || actual || ' expected to be not null');
    END is_not_null;

    PROCEDURE is_not_null(actual VARCHAR2) IS
    BEGIN
        IF (actual IS NOT NULL) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'actual: ' || actual || ' expected to be not null');
    END is_not_null;

    FUNCTION boolean_to_varchar(bool BOOLEAN) RETURN VARCHAR2 IS  
    BEGIN
        RETURN CASE bool
            WHEN TRUE THEN 'true'
            WHEN FALSE THEN 'false'
        END; 
    END boolean_to_varchar;

    PROCEDURE is_true(actual BOOLEAN) IS
    l_actual varchar2(1);
    BEGIN
        IF (actual) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'actual: ' || boolean_to_varchar(actual) || ' expected to be true');
    END is_true;

    PROCEDURE is_false(actual BOOLEAN) IS
    BEGIN
        IF (NOT(actual)) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'actual: ' ||  boolean_to_varchar(actual) || ' expected to be false');
    END is_false;

    PROCEDURE less_than(expected INT, actual INT) IS
    BEGIN
        IF (expected < actual) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'expected: ' || expected || ' to be less than actual: ' || actual );
    END less_than;

    PROCEDURE greater_than(expected INT, actual INT) IS
    BEGIN
        IF (expected > actual) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'expected: ' || expected || ' to be greater than actual: ' || actual );
    END greater_than;

END ASSERT;
/
