#!/usr/bin/perl
use Data::Dumper;
use ExtUtils::Installed;

my $inst = ExtUtils::Installed->new();
my @modules = $inst->modules();
print Dumper(@modules);