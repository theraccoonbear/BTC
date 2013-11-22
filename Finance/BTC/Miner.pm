package Finance::BTC::Miner;

use Moose;
use Digest::MD5 qw(md5);
use Digest::SHA1 qw(sha1);
use Digest::SHA qw(sha256);
use Time::HiRes qw(gettimeofday);
#use bigint;

has 'difficulty' => (
	is => 'rw',
	isa => 'Num',
	default => sub {
	  return 1;
	}
);

has 'hash' => (
	is => 'rw',
	isa => 'Str',
	default => 'sha256'
);

sub getTarget {
	my $self = shift @_;
	
	if ($self->difficulty < 1) {
		$self->difficulty(1);
	} elsif ($self->difficulty > 100) { #$self->getPadLength()) {
		$self->difficulty(100); #$self->getPadLength());
	}
	
	my $maximum = ('9' x ($self->getPadLength - $self->difficulty)) * 1;
	my $percent = ((100 - $self->difficulty) / 100);
	my $targ = $maximum * $percent;
	#print "Diff: " . $self->difficulty . "\n";
	#print "Max: $maximum\n";
	##print "Max: " . ($maximum / 3) . "\n";
	#print "Percent: $percent%\n";
	#print "New Target: $targ\n";
	#exit(0);
	return $targ;
	#return ('9' x ($self->getPadLength - $self->difficulty)) * 1;
}


sub getHash {
	my $self = shift @_;
	my $data = shift @_;
	my $hash = $self->hash;
	my $returned;
	
	if ($hash eq 'sha1') {
		$returned = sha1($data);
	} elsif ($hash eq 'sha256') {
		$returned = sha256($data);
	} else {
		$returned = md5($data);
	}
	my @ints = unpack('N*', $returned);
	return join('', @ints);# * 1;
} # getHash()

sub getPadLength {
	my $self = shift @_;
	my $pad_length;
	if ($self->hash eq 'md5') {
		$pad_length = 32;
	} elsif ($self->hash eq 'sha1') {
		$pad_length = 40;
	} elsif ($self->hash eq 'sha256') {
		$pad_length = 80;
	}
	return $pad_length;
} # getPadLength()

sub findNonce {
	my $self = shift @_;
	my $data = shift @_;
	my $difficulty = $self->getTarget();
	
	my $nonce = -1;
	my $cksum = 0;
	my $cnt = 0;
	my $now = gettimeofday();
	my $last_sec = 0;
	my $pad_length = $self->getPadLength();
	
	
	do {
		$nonce++;
		$cksum = $self->getHash($data . $nonce); 
	} while ($cksum > $difficulty);
	my $done = gettimeofday();
	
	return {
		nonce => "$nonce",
		__checksum => ('0' x ($pad_length - length($cksum))) . $cksum,
		data => $data,
		hash => '' . $self->hash(),
		difficulty => ('0' x ($pad_length - length($difficulty))) . $difficulty,
		elapsed => $done - $now
	};
} # findNonce()

1;