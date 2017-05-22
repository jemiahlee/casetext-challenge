#!/usr/bin/env perl

use warnings;
use strict;

my $verbose = 0;

our $reporters = initialize_reporters('reporters.txt');

undef $/;
my $file_content = <>;
my %citations;
while($file_content =~ m{((\d+ \s ((?:[A-Z\d][a-z.]+ \s){0,4}[A-Z\d][a-z.]+)) (?:(, \s at \s \d+)| \s (\d+)))}gx) {
    my($citation, $short_cite, $reporter, $repeated_cite, $first_cite) = ($1, $2, $3, $4, $5);

    print $citation, ", '", $reporter, "'\n" if $verbose;
    next unless $reporters->{$reporter};

    if( $first_cite ) {
        print "  first time, setting '$short_cite' to 1\n" if $verbose;
        $citations{$short_cite} = {
            count => 1,
            full_citation => $citation,
        }
    }
    else {
        $citations{$short_cite}{count}++;
        print "  $citations{$short_cite}{count} time, incrementing '$short_cite'\n" if $verbose;
    }
}

foreach my $short_cite (sort keys %citations) {
    print join(',', $ARGV, $citations{$short_cite}{full_citation}, $citations{$short_cite}{count}), "\n";
}

# function to populate the %reporters hash with the reporters
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
