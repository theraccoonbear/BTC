#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Digest::MD5 qw(md5 md5_hex);
use Digest::SHA1 qw(sha1);
use Digest::SHA qw(sha256);
use Getopt::Long;
use Time::HiRes qw(gettimeofday tv_interval);
use bigint;
use POSIX;

my $previous_fh = select(STDOUT);
$| = 1;
select($previous_fh);

my $difficulty = -1;
my $verbose = 0;
my $tick = 0;
my $data = 'hello, world!';
my $hash = 'md5';
my $pad_length = 32;

GetOptions (
						"difficulty=s" => \$difficulty,
						"data=s"   => \$data,
						'verbose' => \$verbose,
						'tick' => \$tick,
						'hash=s', \$hash);


if ($hash eq 'md5') {
	$pad_length = 32;
} elsif ($hash eq 'sha1') {
	$pad_length = 40;
} elsif ($hash eq 'sha256') {
	$pad_length = 80;
}

if ($difficulty < 1) {
	$difficulty = 1;
} elsif ($difficulty > $pad_length) {
	$difficulty = $pad_length;
}


$difficulty = ('9' x ($pad_length - $difficulty)) * 1;

sub getHash {
	my $data = shift @_;
	my $hash = shift @_ || 'md5';
	my $returned;
	
	if ($hash eq 'sha1') {
		$returned = sha1($data);
	} elsif ($hash eq 'sha256') {
		$returned = sha256($data);
	} else {
		$returned = md5($data);
	}
	my @ints = unpack('N*', $returned);
	return join('', @ints) * 1;
} # getHash()

sub findNonce {
	my $data = shift @_;
	my $difficulty = shift @_;
	
	my $nonce = 0;
	my $cksum = 0;
	my $cnt = 0;
	my $now = gettimeofday();
	my $last_sec = -1;
	
	#if ($tick) {
	#	print '.';
	#}
	
	do {
		$cksum = getHash($data . $nonce, $hash); 
		$nonce++;
		my $elap = floor(gettimeofday() - $now);
		if ($verbose) {
			print "$cksum > $difficulty = " . ($cksum > $difficulty ? 'YES' : 'NO') ."\n";
		} elsif ($tick && ($elap >= $last_sec + 1)) {
			print '.';
			if ($elap != 0 && !($elap % 10)) {
				print $elap . " seconds\n";
			}
			
			$last_sec = $last_sec + 1;
		}
		$cnt++;
	} while ($cksum > $difficulty);
	my $done = gettimeofday();
	
	return {
		nonce => "$nonce",
		attempts => "$cnt",
		__checksum => ('0' x ($pad_length - length($cksum))) . $cksum,
		data => $data,
		hash => "$hash",
		difficulty => ('0' x ($pad_length - length($difficulty))) . $difficulty,
		elapsed => $done - $now
	};
} # findNonce()

my $result = findNonce($data, $difficulty);
print "\n\n";
print Dumper($result);
print "\n\n";