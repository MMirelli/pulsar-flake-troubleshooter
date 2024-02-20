# fix-21556

## Compute differences between actual and expected

1. Reproduce the error by running

```
cd pulsar-flake-utils/fix-21556/data
ptbx_until_test_fails -Pcore-modules -pl pulsar-broker -Dtest=ExtensibleLoadManagerImplTest#testGetMetrics > testout.txt
```

2. Eval `script.el` in your current emacs session 

```
M+x
load-file
pulsar-flake-utils/fix-21556/diff-actual-and-expected-from-failure-file.el
```

> Next step can only be done after `testout.txt` has been produced (1. completed)

3. Generate file containing the differences between actual and expected values, given `testout.txt`. 

```
M+x
fix-21566-test-diff
pulsar-flake-utils/fix-21556/data/testout.txt
```

4. The differences are stored in `pulsar-flake-utils/fix-21556/data/testout-diff.txt`

> Examples of runs I have done are also in `pulsar-flake-utils/fix-21556/data`, I computed those on "Release 3.0.2" - `12c92fed78`.
