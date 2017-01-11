CREATE OR REPLACE PACKAGE ASSERT IS
    PROCEDURE equals(expected VARCHAR2, actual VARCHAR2);
    PROCEDURE equals(expected INT, actual INT);
    PROCEDURE is_null(actual VARCHAR2);
    PROCEDURE is_null(actual INT);
    PROCEDURE is_not_null(actual VARCHAR2);
    PROCEDURE is_not_null(actual INT);
END ASSERT;
/

CREATE OR REPLACE PACKAGE BODY ASSERT IS

    PROCEDURE equals(expected INT, actual INT) IS
    BEGIN
        IF (expected = actual) THEN
            RETURN;
        END IF;

        raise_application_error(-20101, 'expected: ' || expected || '; actual: ' || actual );
    END equals;
    
    PROCEDURE equals(expected VARCHAR2, actual VARCHAR2) IS
    BEGIN
        IF (expected = actual) THEN
            RETURN;
        END IF;
      
        raise_application_error(-20101, 'expected: ' || expected || '; actual: ' || actual );
    END equals;

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

END ASSERT;
/