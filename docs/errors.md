Errors
======
A collection of standard errors / exceptions / etc

- Most exceptions should be considered problems, exiting the process with
  non-zero exit code by default (eg HeaderChecksumFailed)
- Some should exit with 0 (eg UnitTestPassed, or Quit for a user-initiated
  controlled exit)
- There should be variables in the error messages, eg "Invalid cart type: MBC3"
  rather than just "Invalid cart type"

The error objects themselves should contain the string for the error message,
and the exit code -- I don't want the `main()` method (where we catch the errors)
to be deciding how to render each one of them individually.

Ideally there would be some sort of inheritance going on, so that the `main()`
method can catch `EmuError` and all of its sub-errors and not need to handle
eg `HeaderChecksumFailed` and `LogoChecksumFailed` as two different types.