use strict;
use Test::More qw(no_plan);
use lib "lib";

BEGIN { use_ok('Text::DHCPLeases::FPS'); }

my $text = 'failover peer "dhcp-peer" state {
 my state communications-interrupted at 2 2007/08/14 21:10:00;
 partner state normal at 2 2007/08/14 20:51:22;
 mclt 3600;
}
';

my @lines = split /\n/, $text;

my $data = Text::DHCPLeases::FPS->parse(\@lines);
my $fps = Text::DHCPLeases::FPS->new(%$data);
isa_ok($fps, 'Text::DHCPLeases::FPS', 'new');

is($fps->name, 'dhcp-peer', 'name');
is($fps->my_state->{state}, 'communications-interrupted', 'my_state');
is($fps->my_state->{date}, '2 2007/08/14 21:10:00', 'my_state');
is($fps->partner_state->{state}, 'normal', 'partner_state');
is($fps->partner_state->{date}, '2 2007/08/14 20:51:22', 'partner_state');

my $output = $fps->print;
is($output, $text, 'print');

