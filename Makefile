VIRTUALENV=venv
CORPUS_DIR=corpus

virtualenv:
	virtualenv ${VIRTUALENV}
	${VIRTUALENV}/bin/pip install cram

reporter_tests: reporters.txt
	perl -n -e 'chomp; print "$$. $$_ $$.\n";' reporters.txt > tests/cram/basic_reporter_test.input
	perl -n -e 'chomp; print "$$. $$_ $$.\n$$. $$_, at $$.\n$$. $$_ at $$.\n"' reporters.txt > tests/cram/duplicated_reporter_test.input

test:
	@. venv/bin/activate; REPO_DIR=$$(git rev-parse --show-toplevel) cram tests/cram/*.t

cram_fix:
	@. venv/bin/activate; REPO_DIR=$$(git rev-parse --show-toplevel) cram -i tests/cram/*.t

csv:
	find ${CORPUS_DIR} -type f | ./shepardize.pl > citations.csv
