# Oracle PL/SQL Unit Testing

xUnit testing for Oracle PL/SQL

This software is in the Public Domain.  Please see [LICENSE.md](LICENSE.md).

## What is it?

Following the principle of the "least thing that could possibly work", this
package provides exactly TWO procedures:

- `PUNIT_TEST.assert_equals(expected INT, actual INT)`
- `PUNIT_TEST.run_tests(package_name STRING)`

Testing assertions raise a custom exception when they fail (code -20101), and
constructs a suitable message.

Running tests finds and calls all procedures that start with `TEST_` in a
given package, recording which pass (do not raise the custom exception), which
fail (do raise the custom exception), and which error (raises any other
exception).

Failed assertions show the line of code which failed.  Errored tests print a
backtrace (`DBMS_UTILITY.format_error_backtrace()`).  At the end a summary is
printed in the style of maven tests.

Unit tests should have no dependencies on each other, nor any implicit
ordering.  They may be run in any order.

See [`punit_test.sql`](punit_test.sql) for this package.

### Variation

There is a variation of `PUNIT_TEST.run_tests(package_name STRING)`:

- `PUNIT_TEST.run_tests(package_name STRING, boolean die_if_failed DEFAULT true)`

It is a workaround for Oracle discarding output if any part or subpart of a
program does not complete normally.  Regular behavior of `run_tests` is to
reraise any exception or test failure so that compilation of tested code
fails.  This lets failing tests keep bad code out of the database.

However, finding what tests failed is challenging.  In that case, set
`die_if_failed` to `false` to see which test(s) failed.  An alternative
approach would be appreciated.

## Usage

See [`punit_testee.sql`](punit_testee.sql) for a full example.

Use like this:

```plsql
-- In MY_PACKAGE
  PROCEDURE TEST_something IS
    BEGIN
        PUNIT_TEST.assert_equals(3, some_function(2));
    END TEST_something;
```

After writing unit tests in your production package, run them with:

```plsql
BEGIN
  PUNIT_TEST.run_tests('MY_PACKAGE');
END;
```

Example output from `PUNIT_TESTEE`:

```
Running PUNIT_TESTEE
TEST_FAIL failed: ORA-20101: Expected: 3; got: 2 at PUNIT_TESTEE#l18: PUNIT_TEST.assert_equals(3, some_function(2));
TEST_PASS passed.
TEST_ERROR errored: ORA-06501: PL/SQL: program error
ORA-06512: at "MY_PACKAGE.PUNIT_TESTEE", line 6
ORA-06512: at "MY_PACKAGE.PUNIT_TESTEE", line 23
ORA-06512: at line 1
ORA-06512: at "MY_PACKAGE.PUNIT_TEST", line 39

Tests run: 3, Failures: 1, Errors: 1, Skipped: 0, Time elapsed: 0.20 sec - in PUNIT_TESTEE
```
