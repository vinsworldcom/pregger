NAME

PREGGER - Perl Regular Expression Generic Explainer and Tester
Author:  Michael J. Vincent


DESCRIPTION

Script takes the supplied regular expression and explains it with 
YAPE::Regex::Explain (if installed) and the evaluates against supplied 
test strings on command line or in file provided on command line.  If 
capture groups are used, it can display the capture groups if matched.


DEPENDENCIES

  YAPE::Regex::Explain (optional, but needed for --explain option)
