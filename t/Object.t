use strict;
use Test::More qw(no_plan);
use lib "lib";

BEGIN { use_ok('Text::DHCPLeases::Object'); }

my $text = 'lease 192.168.254.55 {
  starts 3 2007/08/15 11:34:58;
  ends 3 2007/08/15 11:44:58;
  tstp 3 2007/08/15 11:49:58;
  tsfp 2 2007/08/14 21:24:19;
  cltt 3 2007/08/15 11:34:58;
  binding state active;
  next binding state expired;
  hardware ethernet 00:11:85:5d:4e:11;
  uid "\001\000\021\205]Nh";
  client-hostname "blah";
}
';

my @lines = split /\n/, $text;

my $lease_data = Text::DHCPLeases::Object->parse(\@lines);
my $lease = Text::DHCPLeases::Object->new(%$lease_data);
isa_ok($lease, 'Text::DHCPLeases::Object', 'new');

is($lease->ip_address, '192.168.254.55', 'address');
is($lease->starts, '3 2007/08/15 11:34:58' , 'start');
is($lease->ends, '3 2007/08/15 11:44:58' , 'ends');
is($lease->tstp, '3 2007/08/15 11:49:58' , 'tstp');
is($lease->tsfp, '2 2007/08/14 21:24:19' , 'tsfp');
is($lease->cltt, '3 2007/08/15 11:34:58' , 'cltt');
is($lease->binding_state, 'active' , 'binding_state');
is($lease->next_binding_state, 'expired' , 'next_binding_state');
is($lease->hardware_type, 'ethernet' , 'hardware-type');
is($lease->mac_address, '00:11:85:5d:4e:11' , 'mac-address');
is($lease->uid, '"\001\000\021\205]Nh"' , 'uid');
is($lease->client_hostname, '"blah"' , 'uid');

my $output = $lease->print;
is($output, $text, 'print');

my $ftext = '
failover peer "dhcp-peer" state {
  my state communications-interrupted at 2 2007/08/14 21:10:00;
  partner state normal at 2 2007/08/14 20:51:22;
  mclt 3600;
}
';

my @flines = split /\n/, $ftext;

my $fdata = Text::DHCPLeases::Object->parse(\@flines);
my $fps = Text::DHCPLeases::Object->new(%$fdata);

is($fps->name, '"dhcp-peer"', 'name');
is($fps->my_state, 'communications-interrupted', 'my_state');
is($fps->my_state_date, '2 2007/08/14 21:10:00', 'my_state_date');
is($fps->partner_state, 'normal', 'partner_state');
is($fps->partner_state_date, '2 2007/08/14 20:51:22', 'partner_state_date');

my $foutput = $fps->print;
is($foutput, $ftext, 'print');

