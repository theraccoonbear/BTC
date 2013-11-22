#!/usr/bin/perl
use strict;
use warnings;
use Finance::BTC::Transaction;
use Finance::BTC::Block;
use Finance::BTC::Miner;
use POSIX;
use Data::Dumper;
use List::Util qw(sum);

my $previous_fh = select(STDOUT);
$| = 1;
select($previous_fh);


my $target_seconds = 10;
my $diff = 1;

my @Names = qw(
	Joe
	Bob
	Jimmy
	Ralph
	Mike
	Steve
	Hector
	Phillipe
	Alice
	Craig
);

sub getName {
	my $not = shift @_  || 0;
	my $name;
	
	do {
		$name = $Names[rand() * scalar @Names];
	} while ($not && $name eq $not);
	
	return $name;
} # getName()

sub getTranBlock {

	my @block = ();
	
	foreach (3..floor(rand() * 15) + 3) {
		my $sender = getName();
		my $recip = getName($sender);
		my $amount = rand() * 100;
		
		my $tran = Finance::BTC::Transaction->new(
			sender => $sender,
			recipient => $recip,
			amount => $amount
		);
		
		push @block, $tran->json();
	}
	
	return @block;
} # getTranBlock()


my $miner = new Finance::BTC::Miner(difficulty => 1);


my $last_hash = '0' x 40;
my @mvng_avg = ();

my $since_last = 0;

do {
	my @block = getTranBlock();
	my $block_str = $last_hash . join(",", @block);

	my $block = $miner->findNonce($block_str);
	#print Dumper($block);
	$last_hash = $block->{__checksum};
	
	push @mvng_avg, $block->{elapsed} * 1;
	if (@mvng_avg >= 10) {
		shift @mvng_avg;

		my $avg = sum(@mvng_avg)/@mvng_avg;
		
		if ($avg < $target_seconds - 1) {
			print "Too fast ($avg not $target_seconds).\nChanged difficulty from " . $miner->difficulty . " to ";
			$miner->difficulty($miner->difficulty + 1);
			print $miner->difficulty . "\n";
		} elsif ($avg > $target_seconds + 1) {
			print "Too slow ($avg not $target_seconds).\nChanged difficulty from " . $miner->difficulty . " to ";
			$miner->difficulty($miner->difficulty - 1);
			print $miner->difficulty . "\n";
		}
	}
	
	
} while (1);

