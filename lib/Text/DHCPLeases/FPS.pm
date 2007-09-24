package Text::DHCPLeases::FPS;

use warnings;
use strict;
use Carp;
use Class::Struct;

use version; our $VERSION = qv('0.1');

my $IPV4  = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

# weekday year/month/day hour:minute:second
my $DATE  = '\d+ \d{4}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2}';

=head1 NAME

Text::DHCPLeases::FPS - Failover Peer State class

=head1 SYNOPSIS

my $fps = Text::DHCPLeases::FPS->new(%data);
print $fps->my_state->{state};
print $fps->partner_state->{state};

=head1 DESCRIPTION

Failover Peer State objects and their operations

=cut

struct (
'name'                 => '$',
'my_state'             => '%',
'partner_state'        => '%',
'mclt'                 => '$',
);

=head1 CLASS METHODS

=head2 new - Constructor
  Arguments:
    name
    my_state
    partner_state
    mclt
  Returns:
    New Text::DHCPLeases::FPS object
  Examples:
    my $fps = Text::DHCPLeases::FPS->new(%data);
    
=cut
############################################################
=head2 parse - Parse failover peer state declaration

  Arguments:
    Array ref with declaration lines
  Returns:
    Hash reference.  
  Examples:
    
my $text = 'failover peer "dhcp-peer" state {
 my state communications-interrupted at 2 2007/08/14 21:10:00;
 partner state normal at 2 2007/08/14 20:51:22;
 mclt 3600;
}';

my @lines = split /\n/, $text;
my $fps_data = Text::DHCPLeases::Lease->parse(\@lines);
=cut
sub parse {
    my ($self, $lines) = @_;
    my %fps;
    for ( @$lines ){
	next if ( /^#|^$|\}$/ );
	if ( /failover peer \"(.*)\" state/ ){
	    $fps{name} = $1;
	}elsif ( /my state (.*) at ($DATE);/ ){
	    $fps{my_state}{state} = $1;
	    $fps{my_state}{date}  = $2;
	}elsif (/partner state (.*) at ($DATE);/ ){
	    $fps{partner_state}{state} = $1;
	    $fps{partner_state}{date}  = $2;
	}elsif (/mclt (\w+);/ ){
	    $fps{mclt} = $1;
	}else{
	    croak "Text::DHCPLeases::FPS::parse Error: Statement not recognized: $_\n";
	}
    }
    return \%fps;
}


=head1 INSTANCE METHODS
=cut

############################################################
=head2 print - Print formatted string with object contents

  Arguments:
    None
  Returns:
    Formatted String
  Examples:
    print $fps->print;
=cut
sub print{
    my ($self) = @_;
    my $out = "";
    $out .= sprintf("failover peer \"%s\" state {\n", $self->name);
    $out .= sprintf(" my state %s at %s;\n", $self->my_state->{state}, $self->my_state->{date});
    $out .= sprintf(" partner state %s at %s;\n", $self->partner_state->{state}, $self->partner_state->{date});
    $out .= sprintf(" mclt %s;\n", $self->mclt);
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
