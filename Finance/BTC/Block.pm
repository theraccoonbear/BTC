package Finance::BTC::Block;

use Moose;
use JSON::XS;
use bigint;
use Data::UUID;
  
has 'hash' => (
	is => 'rw',
	isa => 'Str'
);

has 'transactions' => (
	is => 'rw',
	isa => 'Array(Str)'
);




1;