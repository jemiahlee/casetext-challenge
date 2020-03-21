# Jeremiah's Casetext Coding Challenge #

This is a solution to the problem presented in
[this doc](https://docs.google.com/document/d/15mAWJXfCs4i0e8qyusaXMElqMGrB3q_wOamH6Qi49qI/edit).

## Approach

I've written the code for this challenge in Perl, which is great for
text-based processing. Generally speaking, I probably would not build
a large system around this in Perl, though, opting for Ruby or Python
or a JVM-based language.

The approach for the script is to walk through the input file, looking
for a match to a regular expression that was built. This regular expression
is built from the list of reporters given by the problem definition. The
script builds one large alternation from this list and then wraps the
volume and page numbers around it. Alternations with many different
possibilities can be slow, though the fact that the reporters are all
relatively short does allow this script to not be too slow. Over the
entire corpus, the script runs on my MBP in about 70 seconds, which
doesn't seem that bad to me (in real life, it would depend on the
circumstances whether that was not performant enough). The positive side
of using a large alternation like that is that it will ensure accuracy in
a way that a more generic regex would not. An earlier version of the script
did contain a regex that was not using the alternation. It was able to
match all 1204 reporters in the test file, but it may not have been as
accurate in the wild (I didn't do a side-by-side of it to prove that out).

The testing approach is correspondingly different than what I would do in
Python or Ruby or other languages. Here, I'm using `cram` to do
integration tests on the script. `cram` is a simple test harness that for
each test, runs a command and compares the output of the command with the
"golden" copy of the output that is contained in the test file.

If I were using a language like Python or Ruby, which are more naturally
inclined to module/class organization, in addition to the tests I've
created here, I would write more unit test cases; due to time limitations,
I've opted not to do that for this exercise.

The test files I've created are basically using the reporter file to
generate `VOL REPORTER PAGE_NUMBER` lines, and then running the script
against those to ensure that all are captured. Again, with more time and
a better context, I would hand-curate some example files that would ensure
that the script is entirely accurate.

## Assumptions

1. The corpus of documents is in a subdirectory called `/corpus`. If it's not,
the `Makefile` can be modified so that the `find` looks in the correct directory
for the files.
2. Perl is available on your system
3. (for tests) Python is available on your system, and the virtualenv
package is installed. The tests use [cram](https://pypi.python.org/pypi/cram),
a pretty useful command-line testing tool
4. You have make installed.

## Running the code

There is a `Makefile` in the repo, so as long as you have `make` installed,
you can just type

```bash
make csv
```

which will generate a file named `citations.csv`.

## Running the tests

Running the tests is pretty straightforward:

```bash
make virtualenv
make test
```

This will run the 2 cram test files I've provided.

In order to re-create the test files from the reporters.txt, I've provided
a `Makefile` target to do so:

```bash
make reporter_tests
```

After doing that, assuming the reporters.txt has changed, it will be necessary
to verify that the changes are good, to cram. I've also created a `Makefile`
target to run the cram command so that it interactively asks you whether the
output is valid:

```bash
make cram_fix
```

## Data integrity issues

It looks like in the corpus there are a bunch of second citations that are
not actually second citations in the documents. I've verified in some of
those cases that they indeed do not have first citations. I assume this is
either a data quality issue, or just that the cases got those wrong.

The way the script handles those cases is to print a warning about the citation
to STDERR, and to *not* count that citation. This output could be used to
hand curate those files that seem to be in error.

## Limitations

The code as written would need some major modification to support complex *Id.*
cases (and does not count any *Id.* citations now). For simpler cases, it would
not need much modification at all.

Update on this section: I have added *Id.* support to the solution as well, but
it may be less well-tested than the rest.
