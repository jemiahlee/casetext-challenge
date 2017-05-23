#!/usr/bin/env perl

use warnings;
no warnings qw(numeric);
use strict;

use File::Basename;

our $root_dir = $ENV{REPO_DIR} || './';

our $reporters = initialize_reporters("$root_dir/reporters.txt");

# Perl code note:
# Schwartzian Transform to sort the list of reporters by length,
# longest first. Then we'll join them together by pipes to create
# an alternation regex. The \Q\E sequence is to ensure that the
# characters in the reporter string are treated as characters,
# and not metacharacters, in the regex.
#
# Reasoning note:
# Sorting by length here is important because some of the reporters
# have substrings that are the same, and can cause an early match.
our $reporters_re = join('|', map {"\Q$_->[0]\E"}
                              sort {$b->[1] <=> $a->[1]}
                              map {[$_, length($_)]}
                              keys %$reporters);

my $citation_re = qr{(                    # whole citation
                      (                   # short citation
                       \d+                # volume
                       \s
                       ($reporters_re))   # reporter
                       (?:
                        ,? \s at \s \d+  # repeated citation
                        |
                        \s (\d+)          # page number, first citation
                      )
                     )
                    }x;

# if there are command-line arguments, read filenames from the command line.
# otherwise, get them from STDIN.
if( @ARGV ) {
    process_one_file($_) foreach @ARGV;
}
else {
    while(<>){
        chomp;
        process_one_file($_);
    }
}

# Basic procedure here is to iterate through the file by the regex
# above, and then create a hash that keys off of the short
# cite (ie, "33 F. Supp.") so that we know what to increment
# when we get the repeated citation. We'll store both the count
# and the full citation in the hash, so that we can generate the
# report using the full citation.
sub process_one_file {
    my $filename = shift;
    open my $fh, '<', $filename or die "Couldn't open $filename: $!";

    local $/;
    undef $/;

    my $file_content = <$fh>;

    my %citations;
    while($file_content =~ m{$citation_re}g) {
        my($citation, $short_cite, $reporter, $first_cite) = ($1, $2, $3, $4);

        if( $first_cite ) {
            $citations{$short_cite} = {
                count => 1,
                full_citation => $citation,
                reporter => $reporter,
            }
        }
        else {
            unless( $citations{$short_cite} ) {
                print STDERR 'WARNING: found a second citation format for ',
                             "$citation in $filename without a first citation!",
                             " Skipping...\n";
                next;
            }
            $citations{$short_cite}{count}++;
        }
    }

    my $basename = basename($filename);

    # sort by volume number, then by reporter.
    my @key_list = sort {$a <=> $b ||
                         $citations{$a}{reporter} cmp $citations{$b}{reporter}}
                   keys %citations;

    foreach my $short_cite (@key_list) {
        # ensure that CSV parsers can handle this file correctly
        # since there is a reporter that has a comma in it. Ideally we would
        # want to use a real CSV generation library, but I don't want
        # dependencies for this exercise.
        my $citation = $citations{$short_cite}{full_citation};
        if( $citation =~ m{,} ) {
            $citation = '"' . $citation . '"';
        }

        print join(',', $basename, $citation, $citations{$short_cite}{count}), "\n";
    }
}


# function to populate the $reporters hash reference with the reporters
# from the file provided.
sub initialize_reporters {
    my $filename = shift;

    open my $fh, '<', $filename or die "Couldn't open $filename: $!";

    my %reporters;

    local $_;
    while(<$fh>) {
        chomp;
        $reporters{$_} = 1;
    }
    close $fh;

    return \%reporters;
}
