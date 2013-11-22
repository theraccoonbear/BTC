package Finance::BTC::Transaction;

use Moose;
use JSON::XS;
use bigint;
use Data::UUID;
  


has 'sender' => (
	is => 'rw',
	isa => 'Str'
);

has 'recipient' => (
	is => 'rw',
	isa => 'Str'
);

has 'amount' => (
	is => 'rw',
	isa => 'Num'
);

has 'timestamp' => (
	is => 'rw',
	isa => 'Int',
	default => sub {
		return time;
	}
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

sub basic {
	my $self = shift;
	
	my $bhr = {
		sender => $self->sender,
		recipient => $self->recipient,
		amount => $self->amount,
		timestamp => $self->timestamp,
		guid => $self->id
	}
}

sub json {
	my $self = shift;
	
	my $bhr = $self->basic();
	
	return encode_json($bhr);
}



1;