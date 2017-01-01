#!/usr/bin/perl
#
# Usage:
#       $ perl cat.pl INPUT_FILE > OUTPUT_FILE
#
# Detailed Example:
#       https://github.com/district10/cat/blob/master/tutorial_cat.pl_.md
#
# Features:
#       -   verbatim    include file:                       %include <-=path=
#       -   recursive   include file:                       @include <-=path=
#       -   verbatim    include file (trim yaml header):    %include </=path=
#       -   recursive   include file (trim yaml header):    @include </=path=
#
# If you don't want the so called trim-yaml-header feature, the older version is much cleaner:
#       https://github.com/district10/cat/blob/f181388065a7a074eb6e100bd91675233d830ed1/bin/cat.pl

use 5.010;
use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

sub inList {                                # is needle in haystack?
    my $needle = shift;
    my @haystack = @_;
    foreach my $hay (@haystack) {
        if ($needle eq $hay) { return 1; }
    }
    return 0;
}

sub preserveLines {
    my $pd = shift;                         # pd: padding
    my $fn = shift;                         # fn: filename
    my $sv = shift;                         # sv: shave
    if (open my $fh, '<', $fn) {            # fh: file handle
        if ($sv == 1) {
            my $f = readline($fh);          # first line of file
            $f =~ s/\r?\n?$//;
            if ($f eq '---') {
                while(<$fh>) {
                    last if /^---\r?\n?$/;  # shave out
                }
                my $b = readline($fh);
                $b =~ s/\r?\n?$//;
                if ($b eq '') {
                } else {
                    print $pd.$b."\n";
                }
            }  else {
                print $pd.$f."\n";
            }
        }
        while(<$fh>) {
            s/\r?\n?$//;
            print $pd.$_."\n";
        }
    } else {
        print STDERR "Error openning file: [".$fn."].\n";
        print    $pd."Error openning file: [".$fn."].\n";
    }
}

sub unfoldLines {
    my $pd = shift;
    my $fn = shift;
    my $sv = shift;                         # sv: shave
    if (! -f $fn) {                         # -f: Entry is a plain file
        print STDERR "Error openning file: [".$fn."].\n";
        print    $pd."Error openning file: [".$fn."].\n";
        return;
    }
    my $ap = abs_path($fn);                 # ap: abs path
    if (&inList($ap, @_) == 1) {
        &preserveLines($pd, $fn, 0);
    } else {
        unshift(@_, $ap);
        open my $fh, '<', $fn or return;
        if ($sv == 1) {
            my $f = readline($fh);
            $f =~ s/\r?\n?$//;
            if ($f eq '---') {
                while(<$fh>) {
                    last if /^---\r?\n?$/;
                }
                my $b = readline($fh);
                $b =~ s/\r?\n?$//;
                if ($b eq '') {
                } else {
                    print $pd.$b."\n";
                }
            }  else {
                print $pd.$f."\n";
            }
        }
        my $dn = dirname($fn);              # dn: dirname
        while(<$fh>) {
            s/\r?\n?$//;
            if (/^(\s*)\@include <([-\/])=([^=]*)=$/) {
                my $p = $1; my $s = $2; my $f = $3;
                if ($f =~ /^.:/ or $f =~ /^\//) {
                    &unfoldLines($pd.$p, $f, $s eq '/' ? 1 : 0, @_);
                } else {
                    &unfoldLines($pd.$p, $dn."/".$f, $s eq '/' ? 1 : 0, @_);
                }
            } elsif (/^(\s*)\%include <([-\/])=([^=]*)=$/) {
                my $p = $1; my $s = $2; my $f = $3;
                if ($f =~ /^.:/ or $f =~ /^\//) {
                    &preserveLines($pd.$p, $f, $s eq '/' ? 1 : 0);
                } else {
                    &preserveLines($pd.$p, $dn."/".$f, $s eq '/' ? 1 : 0);
                }
            } elsif (/^(?<p>\s*)(?<m>[\%\@])\2include <-=(?<f>[^=]*)=$/) {
                print $pd.$+{p}.$+{m}.'include <-='.$+{f}."=\n";
            } else {
                print $pd.$_."\n";
            }
        }
    }
}

if (-f $ARGV[0]) {
    &unfoldLines("", $ARGV[0], 0);
} else {
    print STDERR "Error openning file: [".$ARGV[0]."].\n";
}
