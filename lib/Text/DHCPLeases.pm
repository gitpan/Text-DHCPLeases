package Text::DHCPLeases;

use warnings;
use strict;
use Carp;
use Text::DHCPLeases::Lease;
use Text::DHCPLeases::FPS;
use Text::DHCPLeases::Lease::Iterator;

use version; our $VERSION = qv('0.1');

my $IPV4  = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

# Make sure to return 1
1;

=head1 NAME

Text::DHCPLeases - Parse DHCP Leases file from ISC dhcpd.

=head1 SYNOPSIS

    use Text::DHCPLeases;

    my $dl = Text::DHCPLeases->new("/etc/dhcpd.leases");

    foreach my $lease ( $dl->get_leases ){
        print $lease->address;
        if ( $lease->binding_state eq 'active' ){
           ...
    }
    ...

=head1 DESCRIPTION

This module provides an object-oriented interface to ISC DHCPD leases files.  
The goal is to have access to every declaration and its statements, as
defined by the dhcpd.leases man page from the ISC dhcpd package.

This interface is useful for analyzing, reporting, converting lease files, 
or as a tool for other applications that need to import dhcpd lease data structures.

=head1 CLASS METHODS
=cut

############################################################
=head2 new - Class Constructor

  Arguments:
    Hash with the following keys:
    file  -  Leases file path
  Returns:
    Text::DHCPLeases object
  Examples:
    Text::DHCPLeases->new(file=>"/etc/dhcpd.leases");
=cut
sub new{
    my ($proto, %argv) = @_;
    croak "Missing required parameters: file" unless defined $argv{file};
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{_data} = $self->_parse($argv{file});
    return $self;
}


=head1 INSTANCE METHODS
=cut


############################################################
=head2 get_leases - Get lease objects

  Arguments:
    address - (Optional)
  Returns:
    Array of Text::DHCPLeases::Lease objects, 
    or iterator depending on context
  Examples:
    my $it = $dhcp_leases->get_leases('192.168.0.1');
    while ( my $lease = $it->next ) ...
=cut
sub get_leases{
    my ($self, $address) = @_;
    my @list;
    if ( defined $address ){
	@list = $self->_get_addr_leases($address);
    }else{
	# Use 'all' array to get real order from file
	@list = @{$self->{_data}->{leases}->{all}};
    }
    wantarray? @list : DHCPLeases::Lease::Iterator->new(\@list);
}

############################################################
=head2 get_fps - Get FPS (Failover Peer State) objects

  Arguments:
    peer name - (Optional)
  Returns:
    Array of Text::DHCPLeases::FPS objects, 
    or iterator depending on context
  Examples:
    my $it = $dhcp_leases->get_fps('my_peer');
    while ( my $fps = $it->next ) ...
=cut
sub get_fps{
    my ($self, $name) = @_;
    my @list;
    if ( defined $name ){
	foreach my $fps ( @{$self->{_data}->{fps}->{all}} ){
	    if ( $fps->name eq $name ){
		push @list, $fps;
	    }
	}
    }else{
	@list = @{$self->{_data}->{fps}->{all}};
    }
    wantarray? @list : DHCPLeases::FPS::Iterator->new(\@list);
}

############################################################
=head2 print - Print leases object contents as formatted string

  Arguments:
    None
  Returns:
    Formatted String
  Examples:
    print $leases->print;
=cut
sub print{
    my ($self) = @_;
    my $out = "";
    foreach my $lease ( $self->get_leases ){
	$out .= $lease->print;
    }
    return $out;
}

############################################################
#
# ********* PRIVATE METHODS **********
#
############################################################


############################################################
# Return all the leases with a given address
sub _get_addr_leases{
    my ($self, $address) = @_;
    croak "Missing required argument: address" unless defined $address;
    # $list contains an reference to an array of hashes containing lease data
    my $list = $self->{_data}->{leases}->{byaddress}->{$address} 
    || croak "Leases with address $address not found\n";
    return @$list;
}

############################################################
# _parse - Populate array of objects after reading file
#
# Arguments:
#    filename
# Returns:
#    Hash reference.  
#    Key:   declaration header
#    Value: hash ref with declaration data
#
sub _parse {
    my ($self, $file) = @_;
    my %data;
    my $declist = $self->_get_decl($file);
    foreach my $decl ( @$declist ){
	my $header = $decl->{header};
	my $lines  = $decl->{lines};
	if ( $header =~ /lease ($IPV4)/ ){
	    my $address = $1;
	    my $lease_data = Text::DHCPLeases::Lease->parse($lines);
	    my $lease = Text::DHCPLeases::Lease->new(%$lease_data);
	    push @{$data{leases}{byaddress}{$address}}, $lease;
	    push @{$data{leases}{all}}, $lease;
	}elsif ( $header =~ /failover peer (.*) state/ ){
	    my $fps_data = Text::DHCPLeases::FPS->parse($lines);
	    my $fps = Text::DHCPLeases::FPS->new(%$fps_data);
	    push @{$data{fps}{all}}, $fps;
	}else{
	    croak "Text::DHCPLeases::_parse Error: Declaration header not recognized: $header\n";
	}
    }
    return \%data;
}

############################################################
# _get_decl - Parse file and return all declarations
#
# Arguments:
#    filename
# Returns:
#    Array ref of hashrefs.  
#    
sub _get_decl {
    my ($self, $file) = @_;
    open(FILE, "<$file") or croak "Can't open file $file: $!\n";
    my @list;
    my $lines = [];
    my $header;
    my $open = 0;
    my $decl;
    while ( <FILE> ){
	my $line = $_;
	$line =~ s/^\s*(.*)\s*$/$1/;
	next if ( $line =~ /^#|^$/ );
	if ( !$open && $line =~ /^(.*) \{$/ ){
	    $decl = {};
	    $header = $1;
	    $header =~ s/^(.*) \{$/$1/;
	    $decl->{header} = $header;
  	    $open   = 1;
	    $lines  = [];
	    push @$lines, $line;
	    next;
	}
	if ( $open ){
	    if ( $line =~ /^\}$/ ){
		$open = 0;
		$decl->{lines}  = $lines;
		push @list, $decl;
		$header = "";
		push @$lines, $line;
	    }else{
		push @$lines, $line;
	    }
	}
    }
    close(FILE);
    return \@list;
}


=head1 BUGS AND LIMITATIONS

Correct parsing of leases files depends on changes made to the format of
said files by the authors of the ISC DHCPD package.  This module was tested
against leases files generated by ISC DHCPD version 3.1.0.  In addition, I
do not have access to leases file with all possible declarations and statements,
so parsing could be broken in some circumstances.  Patches are welcome.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-Text-DHCPleases@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


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
