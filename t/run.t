#!/usr/bin/env perl
use Modern::Perl;
use Test::More;
use Try::Tiny;
use Carp qw(croak carp confess);

my $class = 'Drug::Reaction';
require_ok( $class );

use Drug::Reaction;
my $object = Drug::Reaction->new();
isa_ok($object, $class);

can_ok($object, 'drug_reaction_main');
can_ok($object, 'drug_analysis');
can_ok($object, 'init_db');
can_ok($object, 'upload_to_db');


done_testing();
