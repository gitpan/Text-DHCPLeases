package DHCPLeases::Object::Iterator;

use strict;
use warnings;

use version; our $VERSION = qv('0.3');

=head1 NAME

Text::DHCPLeases::Object::Iterator - Lease object iterator class

=head1 SYNOPSIS


=head1 DESCRIPTION
=cut


sub new {
    my ($proto, $list) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
    $self->{_list} = $list;
    $self->{_pos}  = 0;
    $self->{_size} = scalar @{$self->{_list}};
    bless $self, $class;
}

sub count { my ($self) = @_; return $self->{_size} };

sub first {
    my ($self) = @_;
    return $self->{_list}->[0];
}

sub last {
    my ($self) = @_;
    return $self->{_list}->[$self->{_size} - 1];
}

sub next {
    my ($self) = @_;
    $self->{_pos}++;
    return $self->{_list}->[$self->{_pos}];
}

# Make sure to return 1
1;



=head1 AUTHOR

Carlos Vicente, C<< <cvicente at ns.uoregon.edu> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007-2010 University of Oregon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

