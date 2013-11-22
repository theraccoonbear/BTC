#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Digest::MD5 qw(md5 md5_hex);
use Digest::SHA1 qw(sha1);
use Digest::SHA qw(sha256);
use Getopt::Long;
use Time::HiRes qw(gettimeofday);
use bigint;
use POSIX;

# This is a simple hashing script
#
# It is not a BTC miner, it's a very simple
# implementation of the ideas used in BTC
# transaction processing/mining.
#
# This is just a simple tool to help illustrate
# how hash difficulty works.

# Sample Output:
#
# $ ./hasher.pl --data "Xmy test data" --tick --hash sha256 --difficulty 12
# ..........10 seconds (52067 hashes tested; 5 KH/s)
# ..........20 seconds (104105 hashes tested; 5 KH/s)
# ..........30 seconds (155522 hashes tested; 5 KH/s)
# ..........40 seconds (206747 hashes tested; 5 KH/s)
# ..........50 seconds (257908 hashes tested; 5 KH/s)
# ..........60 seconds (309090 hashes tested; 5 KH/s)
# ..........70 seconds (361264 hashes tested; 5 KH/s)
# ..........80 seconds (413432 hashes tested; 5 KH/s)
# ..........90 seconds (465044 hashes tested; 5 KH/s)
# ..........100 seconds (517306 hashes tested; 5 KH/s)
# ..........110 seconds (569621 hashes tested; 5 KH/s)
# ..........120 seconds (621909 hashes tested; 5 KH/s)
# ..........130 seconds (674173 hashes tested; 5 KH/s)
# ..........140 seconds (726542 hashes tested; 5 KH/s)
# ..........150 seconds (778885 hashes tested; 5 KH/s)
# ..........160 seconds (831158 hashes tested; 5 KH/s)
# ..........170 seconds (883491 hashes tested; 5 KH/s)
# ..........180 seconds (935765 hashes tested; 5 KH/s)
# ..........190 seconds (987982 hashes tested; 5 KH/s)
# ..........200 seconds (1040169 hashes tested; 5 KH/s)
# ..
# 
# $VAR1 = {
#           'hash' => 'sha256',
#           'difficulty' => '00000000000099999999999999999999999999999999999999999999999999999999999999999999',
#           '__checksum' => '00000000000044859553546166089426248694455243727540602698974690741819993069296615',
#           'nonce' => '1052971',
#           'data' => 'Xmy test data',
#           'attempts' => '1052971',
#           'elapsed' => '202.446646928787'
#         };



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
	'hash=s', \$hash
);


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

sub hrf {
	my $num = shift @_;
	my @sizes=('', 'K', 'M', 'G', 'T', 'P');
  my $i = 0;

  while ($num > 1024)
  {
    $num = $num / 1024;
    $i++;
  }
  return sprintf("%.0f $sizes[$i]", $num);
} # hrf()

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
	my $last_sec = 0;
	
	do {
		$cnt++;
		$cksum = getHash($data . $nonce, $hash); 
		$nonce++;
		my $elap = floor(gettimeofday() - $now);
		if ($verbose) {
			print "$cksum > $difficulty = " . ($cksum > $difficulty ? 'YES' : 'NO') ."\n";
		} elsif ($tick && ($elap >= $last_sec + 1)) {
			print '.';
			if ($elap != 0 && !($elap % 10)) {
				my $hash_rate = hrf($cnt / $elap);
				print $elap . " seconds ($cnt hashes tested; " . $hash_rate . "H/s)\n";
			}
			
			$last_sec = $last_sec + 1;
		}
		
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