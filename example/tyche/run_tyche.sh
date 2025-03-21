#!/usr/bin/env sh

# custom script to run qcheck-tyche and filter non reproducible parts

OUT=`./QCheck_tyche_test.exe $@`
CODE=$?

# remove non deterministic output
echo "$OUT" \
  | grep -v 'File .*, line .*' \
  | grep -v 'Called from ' \
  | grep -v 'Raised at ' \
  | grep -v '(in the code)' \
  | sed 's/in: .*seconds/in: <nondet> seconds/'
exit $CODE
