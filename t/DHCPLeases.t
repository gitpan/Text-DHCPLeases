use strict;
use Test::More qw(no_plan);
use lib "lib";

BEGIN { use_ok('Text::DHCPLeases'); }

my $dl = Text::DHCPLeases->new(file=>'t/dhcpd.leases.sample');
isa_ok($dl, 'Text::DHCPLeases', 'Constructor');

my $it = $dl->get_leases();
is($it->count, 29, 'count');
is($it->first->address, '192.168.10.87', 'get_leases2');
is($it->last->address, '192.168.10.55', 'get_leases3');

$it = $dl->get_leases('192.168.10.55');
is($it->last->tsfp, '3 2007/08/15 20:31:07', 'get_leases1');

