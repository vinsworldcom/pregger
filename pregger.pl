#!perl
##################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
##################################################

use vars qw($VERSION);

$VERSION = "1.0 - 29 JUL 2015";

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);    #bundling
use Pod::Usage;

##################################################
# Start Additional USE
##################################################
my $HAVE_YAPE_Regex_Explain = 0;
eval "use YAPE::Regex::Explain";
if ( !$@ ) {
    $HAVE_YAPE_Regex_Explain = 1;
}
##################################################
# End Additional USE
##################################################

my %opt;
my ( $opt_help, $opt_man, $opt_versions );

GetOptions(
    'bare!'      => \$opt{bare},
    'capture!'   => \$opt{capture},
    'explain!'   => \$opt{explain},
    'm|matches!' => \$opt{matches},
    'perlish!'   => \$opt{perlish},
    'help!'      => \$opt_help,
    'man!'       => \$opt_man,
    'versions!'  => \$opt_versions
) or pod2usage( -verbose => 0 );

pod2usage( -verbose => 1 ) if defined $opt_help;
pod2usage( -verbose => 2 ) if defined $opt_man;

if ( defined $opt_versions ) {
    print
      "\nModules, Perl, OS, Program info:\n",
      "  $0\n",
      "  Version                $VERSION\n",
      "    strict               $strict::VERSION\n",
      "    warnings             $warnings::VERSION\n",
      "    Getopt::Long         $Getopt::Long::VERSION\n",
      "    Pod::Usage           $Pod::Usage::VERSION\n";
##################################################
# Start Additional USE
##################################################
    if ($HAVE_YAPE_Regex_Explain) {
        print "    YAPE::Regex::Explain $YAPE::Regex::Explain::VERSION\n";
    } else {
        print "    YAPE::Regex::Explain [NOT INSTALLED]\n";
    }
##################################################
# End Additional USE
##################################################
    print
      "    Perl version         $]\n",
      "    Perl executable      $^X\n",
      "    OS                   $^O\n",
      "\n\n";
    exit;
}

##################################################
# Start Program
##################################################
# Make sure at least one host provided
if ( !@ARGV ) {
    pod2usage( -verbose => 0, -message => "$0: regex required\n" );
}

### DEFAULTS
my $HEADER = "Testing: %-30s : ";

$opt{perlish} = $opt{perlish} || 0;
$opt{bare}    = $opt{bare}    || 0;

# --bare implies --matches if no match argument provided
# and overrides -c, -e (-p is part of if/elsif display option)
if ( $opt{bare} ) {
    if ( !defined $opt{matches} ) {
        $opt{matches} = 1;
    }
    $opt{capture} = 0;
    $opt{explain} = 0;
}

# Capture / Explain by default if not already spec'd
if ( !defined $opt{capture} ) {
    $opt{capture} = 1;
}
if ( !defined $opt{explain} ) {
    $opt{explain} = 1;
}

# If --nomatches and --capture, override capture to 0
# since we'll never capture if we're not matching.
# Necessary to get output printing of newline between tests.
if ( defined $opt{matches} and !$opt{matches} ) {
    $opt{capture} = 0;
}
### END DEFAULTS

# REGEX to evaluate
my $regex = $ARGV[0];
# strip leading / if found
$regex =~ s/^\///;
# strip trailing / if found
$regex =~ s/\/$//;
$regex = qr/$regex/;

if ( $opt{explain} ) {
    if ($HAVE_YAPE_Regex_Explain) {
        print YAPE::Regex::Explain->new($regex)->explain;
    } else {
        print "$0: YAPE::Regex::Explain required for -e, skipping ...\n";
    }
    print "\n";
}

if ( defined $ARGV[1] ) {

    my @tests = getTests();

    for my $test (@tests) {
        if ( $test =~ $regex ) {

            # if matches not provided or --matches
            if ( ( !defined $opt{matches} ) or $opt{matches} ) {
                if ( $opt{bare} ) {
                    print "$test\n";
                } elsif ( $opt{perlish} ) {
                    print "\"$test\" =~ /$regex/\n";
                } else {
                    printf $HEADER . "MATCH\n", $test;
                }

                # print captures
                if ( $opt{capture} ) {
                    if ( defined $1 ) {
                        print "    \$1 = $1\n";
                    }
                    if ( defined $2 ) {
                        print "    \$2 = $2\n";
                    }
                    if ( defined $3 ) {
                        print "    \$3 = $3\n";
                    }
                    if ( defined $4 ) {
                        print "    \$4 = $4\n";
                    }
                    if ( defined $5 ) {
                        print "    \$5 = $5\n";
                    }
                    if ( defined $6 ) {
                        print "    \$6 = $6\n";
                    }
                    if ( defined $7 ) {
                        print "    \$7 = $7\n";
                    }
                    if ( defined $8 ) {
                        print "    \$8 = $8\n";
                    }
                    if ( defined $9 ) {
                        print "    \$9 = $9\n";
                    }
                }
            }
        } else {

            # if matches not provided or --nomatches
            if ( ( !defined $opt{matches} ) or !$opt{matches} ) {
                if ( $opt{bare} ) {
                    print "$test\n";
                } elsif ( $opt{perlish} ) {
                    print "\"$test\" !~ /$regex/\n";
                } else {
                    printf $HEADER . "NO MATCH\n", $test;
                }
            }
        }
        if ( $opt{capture} ) {
            print "\n";
        }

    }
}

##################################################
# Start Subs
##################################################

sub getTests {
    my @args = @ARGV;
    shift @args;

    my @tests;
    for my $test (@args) {

        # try to open as file first
        if ( -e $test ) {
            open my $IN, '<', $test;
            my @tTests;
            while (<$IN>) {

                # skip blank lines and #comments
                next if ( ( $_ =~ /^[\n\r]+$/ ) or ( $_ =~ /^#/ ) );
                chomp $_;

                # push to temp array
                push @tTests, $_;
            }

            # clean up - add temp tests to final test array
            close $IN;
            push @tests, @tTests;

            # not a file, push test to array
        } else {
            push @tests, $test;
        }
    }
    return @tests;
}

__END__

=head1 NAME

PREGGER - Perl Regular Expression Generic Explainer and Tester

=head1 SYNOPSIS

 pregger [options] regex [test string 1] ...

=head1 DESCRIPTION

Script takes the supplied regular expression and explains it with 
YAPE::Regex::Explain (if installed) and the evaluates against supplied 
test strings on command line or in file provided on command line.  If 
capture groups are used, it can display the capture groups if matched.

=head1 ARGUMENTS

 regex        The Perl regular expression to evaluate.  
              Use double-quotes to delimit.

 teststr...   Test strings to evaluate against the regular 
              expression.  Must be double-quote delimited if 
              contains spaces.
              
              The "test string #' arguments are fist evaluated as 
              a file name.  If the file exists, assumes file of 
              test expressions with one test expression per line.
              Blank lines and lines starting with '#' are ignored.

=head1 OPTIONS

 -b           Only print 'teststr' and only if match.  Implies -m.
 --bare       Use '--nomatches' to print only 'teststr' that don't 
              match.  Overrides -c, -e, -p.

 -c           If regex contains capture groupings, print out 
 --capture    the values captured to each grouping if match.  
              On by default; use '--nocapture' to disable.

 -e           Use YAPE::Regex::Explain to 'explain' the regular 
 --explain    expression.  On by default; use '--noexplain' to 
              disable.

 -m           Print only matches.
 --matches    Use '--nomatches' to print only no matches.
              Option not used prints both matches and no matches.

 -p           Output match notification in more "Perl-ish" way:
 --perlish      MATCH    ==> "teststr" =~ /regex/
                NO MATCH ==> "teststr" !~ /regex/

 --help       Print Options and Arguments.
 --man        Print complete man page.
 --versions   Print Modules, Perl, OS, Program info.

=head1 EXAMPLES

Assume a file 'file.txt' containing:

  Line#
  1:     foo
  2:     foo bar
  3: 
  4:     # comment
  5:     foo bar baz
  6:

=head2 Basic

  > pregger "/(?:(.*?\s)(.*))/" hello file.txt "hello world"

  The regular expression:

  (?-imsx:(?:(.*?\s)(.*)))

  matches as follows:

  NODE                     EXPLANATION
  ----------------------------------------------------------------------
  (?-imsx:                 group, but do not capture (case-sensitive)
                           (with ^ and $ matching normally) (with . not
                           matching \n) (matching whitespace and #
                           normally):
  ----------------------------------------------------------------------
    (?:                      group, but do not capture:
  ----------------------------------------------------------------------
      (                        group and capture to \1:
  ----------------------------------------------------------------------
        .*?                      any character except \n (0 or more
                                 times (matching the least amount
                                 possible))
  ----------------------------------------------------------------------
        \s                       whitespace (\n, \r, \t, \f, and " ")
  ----------------------------------------------------------------------
      )                        end of \1
  ----------------------------------------------------------------------
      (                        group and capture to \2:
  ----------------------------------------------------------------------
        .*                       any character except \n (0 or more
                                 times (matching the most amount
                                 possible))
  ----------------------------------------------------------------------
      )                        end of \2
  ----------------------------------------------------------------------
    )                        end of grouping
  ----------------------------------------------------------------------
  )                        end of grouping
  ----------------------------------------------------------------------

  Testing: hello                          : NO MATCH

  Testing: foo                            : NO MATCH

  Testing: foo bar                        : MATCH
      $1 = foo
      $2 = bar

  Testing: foo bar baz                    : MATCH
      $1 = foo
      $2 = bar baz

  Testing: hello world                    : MATCH
      $1 = hello
      $2 = world

=head2 No Explanation, Just Testing

  > pregger --noexplain "/(?:(.*?\s)(.*))/" hello file.txt "hello world"

=head2 Just Show Matches, No Capture

  > pregger --noexplain --matches --nocapture "/(?:(.*?\s)(.*))/" hello file.txt "hello world"
  Testing: foo bar                        : MATCH
  Testing: foo bar baz                    : MATCH
  Testing: hello world                    : MATCH

=head2 More Perl-ish

  > pregger --noexplain --nocapture --perlish "/(?:(.*?\s)(.*))/" hello file.txt "hello world"
  "hello" !~ /(?^:(?:(.*?\s)(.*)))/
  "foo" !~ /(?^:(?:(.*?\s)(.*)))/
  "foo bar" =~ /(?^:(?:(.*?\s)(.*)))/
  "foo bar baz" =~ /(?^:(?:(.*?\s)(.*)))/
  "hello world" =~ /(?^:(?:(.*?\s)(.*)))/

=head2 Just the Facts

  > pregger --bare "/(?:(.*?\s)(.*))/" hello file.txt "hello world"
  foo bar
  foo bar baz
  hello world

=head2 Just the Non-Facts

  > pregger --bare --nomatches "/(?:(.*?\s)(.*))/" hello file.txt "hello world"
  hello
  foo

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2015

L<http://www.VinsWorld.com>

All rights reserved

=cut
