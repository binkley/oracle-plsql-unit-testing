SET LINESIZE 1000

DECLARE
    tests PUNIT_TESTING.suite := PUNIT_TESTING.suite('SAMPLE_TEST', 'PUNIT_TESTEE');
BEGIN 
    PUNIT_TESTING.run_suite(tests, raise_on_fail => false);
END;
/