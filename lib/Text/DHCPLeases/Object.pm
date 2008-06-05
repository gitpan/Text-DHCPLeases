package Text::DHCPLeases::Object;

use warnings;
use strict;
use Carp;
use Class::Struct;

use version; our $VERSION = qv('0.5');

# IPv4 regular expression
my $IPV4  = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

# weekday year/month/day hour:minute:second
my $DATE  = '\d+ \d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}';

=head1 NAME

Text::DHCPLeases::Object - Leases Object Class

=head1 SYNOPSIS

my $obj = Text::DHCPLeases::Object->parse($string);

or 

my $obj = Text::DHCPLeases::Object->new(%lease_data);

print $obj->name;
print $obj->type;
print $obj->binding_state;

=head1 DESCRIPTION

DHCPLeases object class.  Lease objects can be one of the following types:

    lease
    host
    group
    subgroup
    failover-state

=cut

struct (
'type'                    => '$',
'name'                    => '$',
'ip_address'              => '$',
'fixed_address'           => '$',
'starts'                  => '$',
'ends'                    => '$',
'tstp'                    => '$',
'tsfp'                    => '$',
'atsfp'                   => '$',
'cltt'                    => '$',
'next_binding_state'      => '$',
'binding_state'           => '$',
'uid'                     => '$',
'client_hostname'         => '$',
'abandoned'               => '$',
'deleted'                 => '$',
'dynamic_bootp'           => '$',
'dynamic'                 => '$',
'option_agent_circuit_id' => '$',
'option_agent_remote_id'  => '$',
'hardware_type'           => '$',
'mac_address'             => '$',
'set'                     => '%',
'on'                      => '%',
'bootp'                   => '$',
'reserved'                => '$',
'my_state'                => '$',
'my_state_date'           => '$',
'partner_state'           => '$',
'partner_state_date'      => '$',
'mclt'                    => '$',
);

=head1 CLASS METHODS

=head2 new - Constructor

  Arguments:
    type                       one of (lease|host|group|subgroup|failover-state)
    name                       identification string (address, host name, group name, etc)
    ip_address
    fixed_address
    starts                     
    ends
    tstp
    tsfp
    atsfp
    cltt
    next_binding_state
    binding_state
    uid
    client_hostname
    abandoned                 (flag)
    deleted                   (flag)
    dynamic_bootp             (flag)
    dynamic                   (flag)
    option_agent_circuit_id
    option_agent_remote_id
    hardware_type
    mac_address
    set                       (hash)
    on                        (hash)
    bootp                     (flag)
    reserved                  (flag)
    my_state
    my_state_date
    partner_state
    partner_state_date
    mclt
  Returns:
    New Text::DHCPLeases::Object object
  Examples:

    my $lease = Text::DHCPLeases::Object->new(type       => 'lease',
                                              ip_address => '192.168.1.10',
                                              starts     => '3 2007/08/15 11:34:58',
                                              ends       => '3 2007/08/15 11:44:58');
   
=cut

############################################################
=head2 parse - Parse object declaration

Arguments:
   Array ref with declaration lines
Returns:
   Hash reference.  
  Examples:

    my $text = '
lease 192.168.254.55 {
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
}';

my $lease_data = Text::DHCPLeases::Lease->parse($text);
=cut
sub parse{
    my ($self, $lines) = @_;
    my %obj;
    for ( @$lines ){
	next if ( /^#|^$|\}$/ );
	if ( /^lease ($IPV4) / ){
	    $obj{type} = 'lease';
	    $obj{name} = $1;
	    $obj{'ip_address'} = $1;
	}elsif ( /^(host|group|subgroup) (.*) / ){
	    $obj{type} = $1;
	    $obj{name} = $2;	
	}elsif ( /^failover peer (.*) state/ ){
	    $obj{type} = 'failover-state';
	    $obj{name} = $1;	
	}elsif ( /starts ($DATE);/ ){
	    $obj{starts} = $1;
	}elsif ( /ends ($DATE);/ ){
	    $obj{ends} = $1;
	}elsif ( /tstp ($DATE);/ ){
	    $obj{tstp} = $1;
	}elsif ( /atsfp ($DATE);/ ){
	    $obj{atsfp} = $1;
	}elsif ( /tsfp ($DATE);/ ){
	    $obj{tsfp} = $1;
	}elsif ( /cltt ($DATE);/ ){
	    $obj{cltt} = $1;
	}elsif ( /next binding state (\w+);/ ){
	    $obj{'next_binding_state'} = $1;
	}elsif ( /binding state (\w+);/ ){
	    $obj{'binding_state'} = $1;
	}elsif ( /uid (\".*\");/ ){
	    $obj{uid} = $1;
	}elsif ( /client-hostname (\".*\");/ ){
	    $obj{'client_hostname'} = $1;
	}elsif ( /abandoned;/ ){
	    $obj{abandoned} = 1;
	}elsif ( /deleted;/ ){
	    $obj{deleted} = 1;
	}elsif ( /dynamic-bootp;/ ){
	    $obj{dynamic_bootp} = 1;
	}elsif ( /dynamic;/ ){
	    $obj{dynamic} = 1;
	}elsif ( /hardware (.+) (.+);/ ){
	    $obj{'hardware_type'} = $1;
	    $obj{'mac_address'}   = $2;
	}elsif ( /fixed-address (.*);/ ){
	    $obj{'fixed_address'} = $1;
	}elsif ( /option agent\.circuit-id (.*);/ ){
	    $obj{'option_agent_circuit_id'} = $1;
	}elsif ( /option agent\.remote-id (.*);/ ){
	    $obj{'option_agent_remote_id'} = $1;
	}elsif ( /set (\w+) = (.*);/ ){
	    $obj{set}{$1} = $2;
	}elsif ( /on (.*) \{(.*)\};/ ){
	    my $events     = $1;
	    my @events = split /\|/, $events;
	    my $statements = $2;
	    my @statements = split /\n;/, $statements;
	    $obj{on}{events}     = @events;
	    $obj{on}{statements} = @statements;
	}elsif ( /bootp;/ ){
	    $obj{bootp} = 1;
	}elsif ( /reserved;/ ){
	    $obj{reserved} = 1;
	}elsif ( /failover peer \"(.*)\" state/ ){
	    $obj{name} = $1;
	}elsif ( /my state (.*) at ($DATE);/ ){
	    $obj{my_state} = $1;
	    $obj{my_state_date} = $2;
	}elsif (/partner state (.*) at ($DATE);/ ){
	    $obj{partner_state} = $1;
	    $obj{partner_state_date} = $2;
	}elsif (/mclt (\w+);/ ){
	    $obj{mclt} = $1;
	}else{
	    croak "Text::DHCPLeases::Object::parse Error: Statement not recognized: $_\n";
	}
    }
    return \%obj;
}

=head1 INSTANCE METHODS
=cut

############################################################
=head2 print - Print formatted string with lease contents

  Arguments:
    None
  Returns:
    Formatted String
  Examples:
    print $obj->print;
=cut
sub print{
    my ($self) = @_;
    my $out = "";
    if ( $self->type eq 'lease' ){
	$out .= sprintf("lease %s {\n", $self->ip_address);	
    }elsif ( $self->type eq 'failover-state' ){
	# These are printed with an extra carriage return in 3.1.0
	$out .= sprintf("\nfailover peer %s state {\n", $self->name);	
    }else{
	$out .= sprintf("%s %s {\n", $self->type, $self->name);
    }
    $out .= sprintf("  starts %s;\n", $self->starts) if $self->starts;
    $out .= sprintf("  ends %s;\n",   $self->ends)   if $self->ends;
    $out .= sprintf("  tstp %s;\n",   $self->tstp)   if $self->tstp;
    $out .= sprintf("  tsfp %s;\n",   $self->tsfp)   if $self->tsfp;
    $out .= sprintf("  atsfp %s;\n",  $self->atsfp)  if $self->atsfp;
    $out .= sprintf("  cltt %s;\n",   $self->cltt)   if $self->cltt;
    $out .= sprintf("  binding state %s;\n",   $self->binding_state)   
	if $self->binding_state;
    $out .= sprintf("  next binding state %s;\n",   $self->next_binding_state)
	if $self->next_binding_state;
    $out .= sprintf("  dynamic-bootp;\n") if $self->dynamic_bootp;
    $out .= sprintf("  dynamic;\n") if $self->dynamic;
    $out .= sprintf("  hardware %s %s;\n", $self->hardware_type, $self->mac_address) 
	if ( $self->hardware_type && $self->mac_address );
    $out .= sprintf("  uid %s;\n", $self->uid) if $self->uid;
    $out .= sprintf("  fixed-address %s;\n", $self->fixed_address) if $self->fixed_address;
    $out .= sprintf("  abandoned;\n") if $self->abandoned;
    $out .= sprintf("  deleted;\n") if $self->abandoned;
    $out .= sprintf("  option agent.circuit-id %s;\n", $self->option_agent_circuit_id) 
	if $self->option_agent_circuit_id;
    $out .= sprintf("  option agent.remote-id %s;\n", $self->option_agent_remote_id) 
	if $self->option_agent_remote_id;
    if ( defined $self->set ){
	foreach my $var ( keys %{ $self->set } ){
	    $out .= sprintf("  set %s = %s;\n", $var, $self->set->{$var});
	}
    }
    if ( $self->on && $self->on->{events} && $self->on->{statements} ){
	my $events = join '|', @{$self->on->{events}};
	my $statements = join '\n;', @{$self->on->{statements}};
	$out .= sprintf("  on %s { %s }", $events, $statements);

    }
    $out .= sprintf("  client-hostname %s;\n", $self->client_hostname) if $self->client_hostname;
    # These are only for failover-state objects
    $out .= sprintf("  my state %s at %s;\n", $self->my_state, $self->my_state_date) 
	if $self->my_state;
    $out .= sprintf("  partner state %s at %s;\n", $self->partner_state, $self->partner_state_date) 
	if $self->partner_state; 
    $out .= sprintf("  mclt %s;\n", $self->mclt) if $self->mclt;
    $out .= "}\n";
    return $out;
}


# Make sure to return 1
1;

=head1 AUTHOR

Carlos Vicente  C<< <<cvicente@cpan.org>> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) <2007-2010>, Carlos Vicente C<< <<cvicente@cpan.org>> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
=cut
