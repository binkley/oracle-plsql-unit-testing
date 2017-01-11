CREATE OR REPLACE PACKAGE PUNIT_TESTEE IS
  FUNCTION Do_It(value INT)
    RETURN INT;
  PROCEDURE Test_Skip; -- Example with mixed case working
  PROCEDURE TEST_Pass;
  PROCEDURE TEST_Fail;
  PROCEDURE TEST_Error;
END PUNIT_TESTEE;
/
CREATE OR REPLACE PACKAGE BODY PUNIT_TESTEE IS
  FUNCTION Do_It(value INT)
    RETURN INT IS
    BEGIN
      IF (3 = value) THEN
        RAISE program_error;
      END IF;
      RETURN value;
    END Do_It;

  PROCEDURE Test_Skip IS
    BEGIN
      PUNIT_TESTING.disable_test('Example skipping a test');

      RAISE program_error; -- Should not reach here
    END Test_Skip;

  PROCEDURE TEST_Pass IS
    BEGIN
      ASSERT.assert_equals(2, Do_It(2));
    END TEST_Pass;

  PROCEDURE TEST_Fail IS
    BEGIN
      ASSERT.assert_equals(3, Do_It(2));
    END TEST_Fail;

  PROCEDURE TEST_Error IS
    BEGIN
      ASSERT.assert_equals(3, Do_It(3));
    END TEST_Error;
END PUNIT_TESTEE;
/
BEGIN
  PUNIT_TESTING.run_tests('PUNIT_TESTEE', raise_on_fail => false);
END;
/
