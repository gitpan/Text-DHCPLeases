package Text::DHCPLeases::Lease;

use warnings;
use strict;
use Carp;
use Class::Struct;

use version; our $VERSION = qv('0.1');

my $IPV4  = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

# weekday year/month/day hour:minute:second
my $DATE  = '\d+ \d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}';

=head1 NAME

Text::DHCPLeases::Lease - Lease class

=head1 SYNOPSIS

my $lease = Text::DHCPLeases::Lease->new(%lease_data);
print $lease->address;
print $lease->binding_state;

=head1 DESCRIPTION

Lease objects and their operations

=cut

struct (
'address'                 => '$',
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
'option_agent_circuit_id' => '$',
'option_agent_remote_id'  => '$',
'hardware'                => '%',
'set'                     => '%',
'on'                      => '%',
'bootp'                   => '$',
'resrved'                 => '$',
);

=head1 CLASS METHODS

=head2 new - Constructor

  Arguments:
    address
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
    abandoned (flag)
    option_agent_circuit_id
    option_agent_remote_id
    hardware (hash)
    set (hash)
    on (hash)
    bootp (flag)
    reserved (flag)
  Returns:
    New Text::DHCPLeases::Lease object
  Examples:

    my $lease = Text::DHCPLeases::Leases->new(address => '192.168.1.10',
                                              starts  => '3 2007/08/15 11:34:58',
                                              ends    => '3 2007/08/15 11:44:58');
   
=cut

############################################################
=head2 parse - Parse lease declaration

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
    my %lease;
    for ( @$lines ){
	next if ( /^#|^$|\}$/ );
	if ( /lease ($IPV4) / ){
	    $lease{address} = $1;
	}elsif ( /starts ($DATE);/ ){
	    $lease{starts} = $1;
	}elsif ( /ends ($DATE);/ ){
	    $lease{ends} = $1;
	}elsif ( /tstp ($DATE);/ ){
	    $lease{tstp} = $1;
	}elsif ( /tsfp ($DATE);/ ){
	    $lease{tsfp} = $1;
	}elsif ( /atsfp ($DATE);/ ){
	    $lease{atsfp} = $1;
	}elsif ( /cltt ($DATE);/ ){
	    $lease{cltt} = $1;
	}elsif ( /next binding state (\w+);/ ){
	    $lease{'next_binding_state'} = $1;
	}elsif ( /binding state (\w+);/ ){
	    $lease{'binding_state'} = $1;
	}elsif ( /uid (\".*\");/ ){
	    $lease{uid} = $1;
	}elsif ( /client-hostname (\".*\");/ ){
	    $lease{'client_hostname'} = $1;
	}elsif ( /abandoned;/ ){
	    $lease{abandoned} = 1;
	}elsif ( /hardware (\w+) (.*);/ ){
	    $lease{hardware}{'hardware-type'} = $1;
	    $lease{hardware}{'mac-address'}   = $2;
	}elsif ( /option agent.circuit-id (\".*\");/ ){
	    $lease{'option_agent_circuit_id'} = $1;
	}elsif ( /option agent.remote-id (\".*\");/ ){
	    $lease{'option_agent_remote_id'} = $1;
	}elsif ( /set (\w+) = (.*);/ ){
	    $lease{set}{$1} = $2;
	}elsif ( /on (.*) \{(.*)\};/ ){
	    my $events     = $1;
	    my @events = split /\|/, $events;
	    my $statements = $2;
	    my @statements = split /\n;/, $statements;
	    $lease{on}{events}     = @events;
	    $lease{on}{statements} = @statements;
	}elsif ( /bootp;/ ){
	    $lease{bootp} = 1;
	}elsif ( /reserved;/ ){
	    $lease{reserved} = 1;
	}else{
	    croak "Text::DHCPLeases::Lease::parse Error: Statement not recognized: $_\n";
	}
    }
    return \%lease;
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
    print $lease->print;
=cut
sub print{
    my ($self) = @_;
    my $out = "";
    $out .= sprintf("lease %s {\n",   $self->address);
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
    $out .= sprintf("  hardware %s %s;\n", $self->hardware->{'hardware-type'}, 
		    $self->hardware->{'mac-address'}) if $self->hardware;
    $out .= sprintf("  uid %s;\n",    $self->uid)   if $self->uid;
    $out .= sprintf("  client-hostname %s;\n", $self->client_hostname) if $self->client_hostname;
    $out .= sprintf("  abandoned %s;\n", $self->abandoned) if $self->abandoned;
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
