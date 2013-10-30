#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use JSON::XS;
use WWW::Mechanize;
use File::Cache;

my $previous_fh;
$previous_fh = select(STDOUT); $| = 1;
select(STDIN); $| = 1;
select(STDERR); $| = 1;
select($previous_fh);

$ENV{TMPDIR} = "$home/tmp";

my $cache = new File::Cache({namespace  => 'BTC',
                             expires_in => 60});
                             #max_size => 1048576,
                             #filemode => 0660,
                             #cache_depth => 3});


my $mtgox_poll_url = 'http://data.mtgox.com/api/2/BTCUSD/money/ticker';
my $coinbase_poll_url = 'https://coinbase.com/api/v1/currencies/exchange_rates';

my $mech = WWW::Mechanize->new();

my $last_mtgox = {};
my $last_coinbase = {};


sub pollMtGox {
  $last_mtgox = $cache->get("mtgox");
  
  if (! defined $last_mtgox) {
	#print STDERR "Polling Mt. Gox...\n";
	$mech->get($mtgox_poll_url);
	my $json = $mech->content;
	my $data = decode_json($json);
	$cache->set("mtgox", $data);
	$last_mtgox = $data;
  } else {
	#print STDERR "Cached respons from Mt. Gox.\n";
  }
}

sub getMtGox {
  my $what = lc(shift @_ || 'sell');
  if ($what !~ m/^(buy|sell)$/) {
	$what = 'sell';
  }
  
  pollMtGox();
  
  my $ret_val = '...';
  
  if ($what eq 'buy') {
	$ret_val = $last_mtgox->{data}->{buy}->{value}
  } else {
	$ret_val = $last_mtgox->{data}->{sell}->{value}
  }
  
  return $ret_val;
}

sub pollCoinbase {
  $last_coinbase = $cache->get("coinbase");

  if (!$last_coinbase) {
	#print STDERR "Polling Coinbase...\n";
	$mech->get($coinbase_poll_url);
	my $json = $mech->content;
	my $data = decode_json($json);
	$cache->set("coinbase", $data);
	$last_coinbase = $data;
  } else {
	#print STDERR "Cached response from Coinbase.\n";
  }
}

sub getCoinbase {
  my $what = lc(shift @_ || 'buy');
  if ($what !~ m/^(buy|sell)$/) {
	$what = 'buy';
  }
  
  pollCoinbase();
  
  my $ret_val = '...';
  
  if ($what eq 'buy') {
	$ret_val = 1 / $last_coinbase->{usd_to_btc};
  } else {
	$ret_val = $last_coinbase->{btc_to_usd};
  }
  
  return $ret_val;
}

sub coinbaseFeesOn {
  my $usd = shift @_;
  return ($usd * 0.01) + 0.15;
}

sub mtgoxFeesOn {
  my $usd = shift @_;
  return ($usd * 0.06);
}

sub dwollaFeesOn {
  my $usd = shift @_;
  return 0.25;
}

sub capitalGainsTaxOn {
  my $usd = shift @_;
  return ($usd * 0.28);
}


sub printIt {  
  my $quantity = 1;
  
  my $mtgox = getMtGox('sell') * $quantity;
  my $coinbase = getCoinbase('buy') * $quantity;
  
  my $gross = $mtgox - $coinbase;
  
  my $coinbase_fees = coinbaseFeesOn($coinbase);
  
  my $mtgox_fees = coinbaseFeesOn($mtgox);
  my $differential = $mtgox - $mtgox_fees;
  
  my $dwolla_fees = dwollaFeesOn($differential);
  $differential -= $dwolla_fees;
  
  my $capital_gains = capitalGainsTaxOn($differential - $coinbase);
  $differential -= $capital_gains;
  
  $differential -= $coinbase;
  
  my $pad = ' ' x (length($quantity) - 1);
  
  
  
  print <<__DATA;

Coinbase Purchase Price ($quantity BTC): \$$coinbase
       MtGox Sell Price ($quantity BTC): \$$mtgox
$pad                  Coinbase Fees: \$$coinbase_fees
$pad                     MtGox Fees: \$$mtgox_fees
$pad                    Dwolla Fees: \$$dwolla_fees
$pad              Capital Gains Tax: \$$capital_gains

$pad                          Gross: \$$gross
$pad                            Net: \$$differential

__DATA

} # printIt();

printIt();

exit(0);
