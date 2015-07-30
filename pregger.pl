#!perl
##################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
##################################################

use vars qw($VERSION);

$VERSION = "1.0 - 29 JUL 2015";

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
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
    '' => \$opt{interact},    # lonesome dash is interactive test from STDIN
    'b|bare!'      => \$opt{bare},
    'c|capture+'   => \$opt{capture},
    'd|debug!'     => \$opt{debug},
    'e|explain!'   => \$opt{explain},
    'm|matches!'   => \$opt{matches},
    'M|multiline!' => \$opt{multiline},
    'p|perlish!'   => \$opt{perlish},
    'help!'        => \$opt_help,
    'man!'         => \$opt_man,
    'versions!'    => \$opt_versions
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
my $EXIT   = 0;
my $HEADER = "Testing: %-30s : ";

$opt{debug}     = $opt{debug}     || 0;
$opt{perlish}   = $opt{perlish}   || 0;
$opt{multiline} = $opt{multiline} || 0;
$opt{bare}      = $opt{bare}      || 0;

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
# lexically scoped, use conditionally here
if ( $opt{debug} ) {
    use re qw(Debug MATCH);
    $regex = qr/$regex/;
} else {
    $regex = qr/$regex/;
}

if ( $opt{explain} ) {
    if ($HAVE_YAPE_Regex_Explain) {
        print YAPE::Regex::Explain->new($regex)->explain;
    } else {
        print "$0: YAPE::Regex::Explain required for -e, skipping ...\n";
    }
    print "\n";
}

if ( defined $ARGV[1] or defined $opt{interact} ) {

    my @tests;

    # Get ARGV first.
    if ( $ARGV[1] ) {
        @tests = getArgTests( \@ARGV );
    }

    # If interactive, this will override all other ARGV tests from above
  INTERACT:
    if ( $opt{interact} ) {
        @tests = getIntTests();
    }

    # SIG{INT} seems unreliable.
    # exit if EXIT set
    exit if $EXIT;

    for my $test (@tests) {
        my $MATCH = 0;
        if ( $test =~ $regex ) {

            $MATCH = 1;

            # if matches not provided or --matches
            if ( ( !defined $opt{matches} ) or $opt{matches} ) {
                if ( $opt{bare} ) {
                    print "----------\n"
                      if ( $opt{multiline} and ( $test =~ /\n/ ) );
                    print "$test\n";
                    print "----------\n"
                      if ( $opt{multiline} and ( $test =~ /\n/ ) );
                } elsif ( $opt{perlish} ) {
                    if ( $opt{multiline} and ( $test =~ /\n/ ) ) {
                        $test =~ s/\n/\\n/g;
                    }
                    print "\"$test\" =~ /$regex/\n";
                } else {
                    if ( $opt{multiline} and ( $test =~ /\n/ ) ) {
                        printf $HEADER . "MATCH\n", "";
                        print "$test\n";
                    } else {
                        printf $HEADER . "MATCH\n", $test;
                    }
                }

                # print captures
                if ( $opt{capture} ) {
                    if ( $opt{capture} == 2 ) {
                        printf "    \${^PREMATCH}  = %s\n",
                          defined ${^PREMATCH} ? ${^PREMATCH} : "";
                        printf "    \${^MATCH}     = %s\n",
                          defined ${^MATCH} ? ${^MATCH} : "";
                        printf "    \${^POSTMATCH} = %s\n",
                          defined ${^POSTMATCH} ? ${^POSTMATCH} : "";
                        printf "    \${^N}         = %s\n",
                          defined ${^N} ? ${^N} : "";
                        printf "    \@-            = (%s)\n", join ",", @-;
                        printf "    \@+            = (%s)\n", join ",", @+;
                    }
                    print "               \$1 = $1\n" if defined $1;
                    print "               \$2 = $2\n" if defined $2;
                    print "               \$3 = $3\n" if defined $3;
                    print "               \$3 = $4\n" if defined $4;
                    print "               \$3 = $5\n" if defined $5;
                    print "               \$3 = $6\n" if defined $6;
                    print "               \$3 = $7\n" if defined $7;
                    print "               \$3 = $8\n" if defined $8;
                    print "               \$3 = $9\n" if defined $9;
                }
            }
        } else {

            # if matches not provided or --nomatches
            if ( ( !defined $opt{matches} ) or !$opt{matches} ) {
                if ( $opt{bare} ) {
                    print "----------\n"
                      if ( $opt{multiline} and ( $test =~ /\n/ ) );
                    print "$test\n";
                    print "----------\n"
                      if ( $opt{multiline} and ( $test =~ /\n/ ) );
                } elsif ( $opt{perlish} ) {
                    if ( $opt{multiline} and ( $test =~ /\n/ ) ) {
                        $test =~ s/\n/\\n/g;
                    }
                    print "\"$test\" !~ /$regex/\n";
                } else {
                    if ( $opt{multiline} and ( $test =~ /\n/ ) ) {
                        printf $HEADER . "NO MATCH\n", "";
                        print "$test\n";
                    } else {
                        printf $HEADER . "NO MATCH\n", $test;
                    }
                }
            }
        }

        # complicated, but required.
        # only add newlines if capture in effect,
        #   but only if we find a match or we don't care about no/match or --match
        if ( $opt{capture}
            and ( $MATCH or ( !defined $opt{matches} ) or !$opt{matches} ) ) {
            print "\n";
        }
    }

    # defined since we may be in here from ARGV and just ready to exit
    if ( defined $opt{interact} ) {
        goto INTERACT;
    }
}

##################################################
# Start Subs
##################################################

sub getArgTests {
    my ($args) = @_;
    shift @{$args};

    my @tests;
    for my $test ( @{$args} ) {

        # try to open as file first
        if ( -e $test ) {
            open my $IN, '<', $test;
            my @tTests;
            my $line;    # for multiline
            while (<$IN>) {
                if ( $opt{multiline} ) {
                    $line .= $_;
                } else {

                    # skip blank lines and #comments
                    next if ( ( $_ =~ /^[\n\r]+$/ ) or ( $_ =~ /^#/ ) );
                    chomp $_;

                    # push to temp array
                    push @tTests, $_;
                }
            }
            if ( $opt{multiline} ) {
                chomp $line;
                push @tTests, $line;
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

sub getIntTests {

    # SIG{INT} seems unreliable.
    # Set EXIT flag, try to exit directly
    $SIG{INT} = sub {
        $EXIT = 1;
        exit;
    };

    my $line;
    print "Enter test> ";

    if ( $opt{multiline} ) {
        while (<STDIN>) {
            $line .= $_;
        }
    } else {
        $line = <STDIN>;
    }

    # SIG{INT} seems unreliable.
    # Use the else to continue otherwise, fall through
    # in this sub leads to exit.
    if ($EXIT) {
        exit;
    } else {
        chomp $line;
        return $line;
    }
    exit;
}

##################################################
# End Program
##################################################

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

 -            Single dash means interactive mode.  Allow user to 
              enter test strings interactively and provide feedback 
              immediately.  Overrides all other command line 'teststr'
              arguments.
              
              If -M, end input and start processing with end of input 
              character:
                Windows : CTRL-z
                Unix    : CTRL-d
              Use CTRL-c to terminate session.

 -b           Only print 'teststr' and only if match.  Implies -m.
 --bare       Use '--nomatches' to print only 'teststr' that don't 
              match.  Overrides -c, -e, -p.

 -c           If regex contains capture groupings, print out 
 --capture    the values captured to each grouping if match.  
              On by default; use '--nocapture' to disable.
              Use multiple times to show more capture information.

 -d           Use 're' module to "Debug MATCH" on the provided 
 --debug      test strings.

 -e           Use YAPE::Regex::Explain to 'explain' the regular 
 --explain    expression.  On by default; use '--noexplain' to 
              disable.

 -m           Print only matches.
 --matches    Use '--nomatches' to print only no matches.
              Option not used prints both matches and no matches.

 -M           Allow multiline test strings (containing '\n').
 --multiline  If enabled, files on command line are read as a single 
              test string rather than individual lines as separate 
              test strings.  If interactive mode, see '-'.

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

=head1 SEE ALSO

The Perl Regex Tester:

L<http://www.perlmonks.org/?node_id=979754>

L<http://retester.herokuapp.com/>

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2015

L<http://www.VinsWorld.com>

All rights reserved

=cut
