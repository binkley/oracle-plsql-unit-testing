# Oracle PL/SQL Unit Testing

xUnit testing for Oracle PL/SQL

## What is it?

Following the principle of the "least thing that could possibly work", this
package provides exactly TWO procedures:

- `PUNIT_TESTING.assert_equals(expected INT, actual INT)`
- `PUNIT_TESTING.run_tests(package_name STRING)`

Testing assertions raise a custom exception when they fail (code -20101), and
construct a suitable message.

Running tests finds and calls all procedures that start with `TEST_` in a
given package, recording which pass (do not raise the custom exception), which
fail (do raise the custom exception), and which error (raise any other
exception).

Failed assertions show the line of code which failed.  Errored tests print a
backtrace (`DBMS_UTILITY.format_error_backtrace()`).  At the end a summary is
printed.

Unit tests should have no dependencies on each other, nor any implicit
ordering.  They may be run in any order.

See [`punit_testing.sql`](punit_testing.sql) for this package.

## Usage

See [`punit_testee.sql`](punit_testee.sql) for a full example.

Use like this:

```plsql
-- In MY_PACKAGE
  PROCEDURE TEST_something IS
    BEGIN
        PUNIT_TESTING.assert_equals(3, some_function());
    END TEST_something;
```

After writing unit tests in your production package, run them with:

```plsql
BEGIN
  PUNIT_TESTING.run_tests('MY_PACKAGE');
END;
```

Example output from `PUNIT_TESTEE`:

```
Testing PUNIT_TESTEE.
TEST_FAIL failed: ORA-20101: Expected: 3; got: 2 at PUNIT_TESTEE#l18: PUNIT_TESTING.assert_equals(3, Do_It(2));
TEST_PASS passed.
TEST_ERROR errored: ORA-06501: PL/SQL: program error
ORA-06512: at "SWMS.PUNIT_TESTEE", line 6
ORA-06512: at "SWMS.PUNIT_TESTEE", line 23
ORA-06512: at line 1
ORA-06512: at "SWMS.PUNIT_TESTING", line 39

Summary: 1 passed, 1 failed, 1 errored.
```

