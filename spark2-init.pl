#!/usr/bin/env perl

BEGIN {
    for (1..$#ARGV) {
        $ARGV[$_] =~ s{^/etc/spark2\.d/}{} if defined $ARGV[$_];
    }
}

use Ubic::Run;

