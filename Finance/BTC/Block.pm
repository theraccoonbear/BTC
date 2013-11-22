package Finance::BTC::Block;

use Moose;
use JSON::XS;
use bigint;
use Data::UUID;
use Data::Dumper;
  
has 'nonce' => (
  is => 'rw',
  isa => 'Int'
);

has 'previous' => (
  is => 'rw',
  isa => 'Str',
  default => sub {
	return '0' x 40;
  }
);

has 'hash' => (
	is => 'rw',
	isa => 'Str'
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

sub addTransaction {
  my $self = shift @_;
  my $tran = shift @_;
  
  push @{ $self->transactions }, $tran;
  #$self->transactions->push($tran), 
}

sub basic {
	my $self = shift;

	my $trans = [];
	foreach my $t (@{ $self->transactions }) {
	  push @{$trans}, $t->basic();
	}
	
	my $bhr = {
		hash => $self->hash,
		finalized => time,
		transactions => $trans,
		previous => $self->previous
	};
	
	return $bhr;
} # basic()

sub json {
	my $self = shift;
	
	my $bhr = $self->basic();
	
	return encode_json($bhr);
} # json()

1;