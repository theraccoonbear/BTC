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
	my $prev = shift @_;
	
	my $block = Finance::BTC::Block->new();
	
	foreach (3..floor(rand() * 15) + 3) {
		my $sender = getName();
		my $recip = getName($sender);
		my $amount = rand() * 100;
		
		my $tran = Finance::BTC::Transaction->new(
			sender => $sender,
			recipient => $recip,
			amount => $amount,
			previous => $prev
		);
		
		$block->addTransaction($tran);
	}
	
	return $block;
	#return @block;
} # getTranBlock()


my $miner = new Finance::BTC::Miner(difficulty => 1);


my $last_hash = '0' x 40;
my @mvng_avg = ();

my $since_last = 0;
my $block_cnt = 0;
my $since_last_adj = 0;

do {
	my $block = getTranBlock($last_hash);
	my $rslt = $miner->findNonce($block->json);
	$block->hash($rslt->{__checksum});
	$block->elapsed($rslt->{elapsed});
	$last_hash = $block->hash;
  
	$block_cnt++;
	$since_last_adj++;
	
	push @mvng_avg, $block->{elapsed} * 1;
	my $to_use = ceil($block_cnt * .1);
	if ($to_use > 100) {
	  $to_use = 100;
	}
	
	print "Window size: $to_use\n";
	
	if (@mvng_avg >= $to_use + 1) {
	  shift @mvng_avg;
	}
	
	
	
	print "$block_cnt block(s) processed.  Last in $rslt->{elapsed}.\n";
	
	#if ($since_last_adj >= 3) {
	  my $avg = sum(@mvng_avg)/@mvng_avg;
	  #$avg = $avg + $rslt->{elapsed} / 2;
	  
	  my $diff = abs($target_seconds - $avg) / $target_seconds;
	  $diff *= .8;
	#  if ($diff > .1) {
	#	$diff = .1;
	#  }
	  
	  #if ($diff > .1) {
		$since_last_adj = 0;
		if ($avg < $target_seconds) {
			print "Too fast ($avg not $target_seconds).\nChanged difficulty from " . $miner->difficulty . " to ";
			$miner->difficulty($miner->difficulty + $diff);
			print $miner->difficulty . "\n";
		} elsif ($avg > $target_seconds) {
			print "Too slow ($avg not $target_seconds).\nChanged difficulty from " . $miner->difficulty . " to ";
			$miner->difficulty($miner->difficulty - $diff);
			print $miner->difficulty . ' (' . $miner->getTarget() . ")\n";
		}
	  #}
	#}
	
} while (1);

