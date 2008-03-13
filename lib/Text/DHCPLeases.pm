package Text::DHCPLeases;

use warnings;
use strict;
use Carp;
use Text::DHCPLeases::Object;
use Text::DHCPLeases::Object::Iterator;

use version; our $VERSION = qv('0.3');

my $IPV4  = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

# Make sure to return 1
1;

=head1 NAME

Text::DHCPLeases - Parse DHCP leases file from ISC dhcpd.

=head1 SYNOPSIS

    use Text::DHCPLeases;

    my $leases = Text::DHCPLeases->new("/etc/dhcpd.leases");

    foreach my $obj ( $leases->get_objects ){
        print $obj->name;
        if ( $obj->binding_state eq 'active' ){
           ...
    }
    ...

=head1 DESCRIPTION

This module provides an object-oriented interface to ISC DHCPD leases files.  
The goal is to objectify all declarations, as defined by the ISC dhcpd package man pages.

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
    $self->{_objects} = $self->_parse($argv{file});
    return $self;
}


=head1 INSTANCE METHODS
=cut


############################################################
=head2 get_objects - Get objects from leases file

  Arguments:
    Object attributes to match (optional)
  Returns:
    Array of Text::DHCPLeases::Lease objects, 
    or iterator depending on context.  
  Examples:
    my $it = $leases->get_objects(ip_address=>'192.168.0.1');
    while ( my $obj = $it->next ) ...
=cut
sub get_objects{
    my ($self, %argv) = @_;
    my @list;
    if ( %argv ){
	foreach my $obj ( @{$self->{_objects}} ){
	    my $match = 1;
	    foreach my $key ( keys %argv ){
		if ( !defined $obj->$key || $obj->$key ne $argv{$key} ){
		    $match = 0;
		    last;
		}
	    }
	    push @list, $obj if $match;
	}
    }else{
	# Use 'all' array to get real order from file
	@list = @{$self->{_objects}};
    }
    wantarray? @list : DHCPLeases::Object::Iterator->new(\@list);
}

############################################################
=head2 print - Print all lease objects contents as a formatted string

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
    foreach my $obj ( $self->get_objects ){
	$out .= $obj->print;
    }
    return $out;
}

############################################################
#
# ********* PRIVATE METHODS **********
#
############################################################


############################################################
# _parse - Populate array of objects after reading file
#
# Arguments:
#    filename
# Returns:
#    Hash reference.  
#    Key:   declaration header
#    Value: reference to array with all objects
#
sub _parse {
    my ($self, $file) = @_;
    my @objects;
    my $declist = $self->_get_decl($file);
    foreach my $decl ( @$declist ){
	my $header = $decl->{header};
	my $lines  = $decl->{lines};
	my $obj;
	if ( $header =~ /^(lease|host|group|subgroup|failover peer)/ ){
	    my $obj_data = Text::DHCPLeases::Object->parse($lines);
	    $obj = Text::DHCPLeases::Object->new(%$obj_data);
	    push @objects, $obj;	
	}else{
	    croak "Text::DHCPLeases::_parse Error: Declaration header not recognized: $header\n";
	}
    }
    return \@objects;
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
