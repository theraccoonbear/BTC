package Finance::BTC::Block;

use Moose;
use JSON::XS;
use bigint;
use Data::UUID;
use Data::Dumper;
use Digest::SHA qw(sha256);
  
has 'nonce' => (
  is => 'rw',
  isa => 'Int'
);

has 'previous' => (
  is => 'rw',
  isa => 'Str',
  default => sub {
	return '0' x 80;
  }
);

has 'hash' => (
	is => 'rw',
	isa => 'Str'
);

has 'target' => (
	is => 'rw',
	isa => 'Str',
	default => sub {
	  return '0' x 80;  
	}
);


has 'transactions' => (
	is => 'rw',
	isa => 'ArrayRef[Finance::BTC::Transaction]',
	default => sub {
	  return [];
	}
);

has 'elapsed' => (
  is => 'rw',
  isa => 'Num'
);

has 'id' => (
	is => 'ro',
	isa => 'Str',
	default => sub {
		my $ug = new Data::UUID;
		my $uuid = $ug->create();
		return $ug->to_string($uuid);
	}
);

sub getHash {
	my $self = shift @_;
	my $data = shift @_;
	#my $hash = 'sha256'; #$self->hash;
	my $returned = sha256($data);;
	
	#if ($hash eq 'sha1') {
	#	$returned = sha1($data);
	#} elsif ($hash eq 'sha256') {
	#	$returned = sha256($data);
	#} else {
	#	$returned = md5($data);
	#}
	my @ints = unpack('N*', $returned);
	return join('', @ints);
} # getHash()

sub getFormattedHash {
	my $self = shift @_;
	my $data = shift @_;
	my $cksum = $self->getHash($data);;
	
	return ('0' x (80 - length($cksum))) . $cksum;
	#my @ints = unpack('N*', $returned);
	#return join('', @ints);
} # getHash()

sub checkNonce {
  my $self = shift @_;
  my $nonce = shift @_ || $self->nonce;
  
  return $self->hash eq $self->getFormattedHash($self->previous . $self->jsonTrans . $self->nonce);
}

sub addTransaction {
  my $self = shift @_;
  my $tran = shift @_;
  
  push @{ $self->transactions }, $tran;
  #$self->transactions->push($tran), 
}

sub basicTrans {
  my $self = shift @_;
  my $trans = [];
  foreach my $t (@{ $self->transactions }) {
	push @{$trans}, $t->basic();
  }
  
  return $trans;
}

sub jsonTrans {
	my $self = shift;
	
	my $bhr = $self->basicTrans();
	
	return encode_json($bhr);
}

sub basic {
	my $self = shift;

	my $bhr = {
		hash => $self->hash,
		finalized => time,
		transactions => $self->basicTrans,
		previous => $self->previous,
		id => $self->id
	};
	
	return $bhr;
} # basic()


sub json {
	my $self = shift;
	
	my $bhr = $self->basic();
	
	return encode_json($bhr);
} # json()

1;