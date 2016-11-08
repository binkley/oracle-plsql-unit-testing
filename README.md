# Oracle PL/SQL Unit Testing

xUnit testing for Oracle PL/SQL

## What is it?

Following the principle of the "least thing that could possibly work", this
package provides exactly TWO procedures:
- `PUNIT_TESTING.assert_equals(expected INT, actual INT)`
- `PUNIT_TESTING.run_tests(package_name STRING)`

Testing assertions raise a custom exception when they fail (code -20101), and
construct a suitable message.

Running tests finds all procedures in a package starting with `TEST_` and
calls them, recording which pass (do not raise exception), which fail (raise
the custom exception), and which error (raise any other exception).  At the
end it prints a summary.

See [`punit_testing.sql`](punit_testing.sql) for this package.

## Usage

See [`punit_testee.sql`](punit_testee.sql) for a full example.

Use like this:

```
MY_PACKAGE:
  PROCEDURE TEST_something IS
    BEGIN
        PUNIT_TESTING.assert_equals(3, some_function());
    END TEST_something;
```

After including unit tests in your production package, run the tests with:

```
BEGIN
  PUNIT_TESTING.run_tests('MY_PACKAGE');
END;
```

Example output:

```
TEST_FAIL failed: ORA-20101: Expected: 3; got: 2
TEST_PASS passed.
TEST_ERROR errored: ORA-06501: PL/SQL: program error
----- PL/SQL Call Stack -----
  object      line  object
  handle    number  name
700000030e25988        34  package body SWMS.PUNIT_TESTING
700000032d880a0         2  anonymous block

Summary: 1 passed, 1 failed, 1 errored.
```

