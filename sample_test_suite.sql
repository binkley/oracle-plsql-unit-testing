SET LINESIZE 1000

DECLARE
    tests PUNIT_RUNNER.suite := PUNIT_RUNNER.suite('SAMPLE_TEST', 'PUNIT_TESTEE');
BEGIN 
    PUNIT_RUNNER.run_suite(tests, raise_on_fail => false);
END;
/