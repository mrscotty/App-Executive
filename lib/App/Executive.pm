package App::Executive;
use 5.008001;
use strict;
use warnings;
use Moose;
use POSIX 'strftime';

our $VERSION = "0.2";

has 'data' => ( is => 'rw', );

sub opt {
    my $self = shift;
    my $id = shift or return;
    my $data = $self->data() or die "Error: data not set";
    if ( @_ ) {
        return $data->{opts}->{$id} = shift;
    } 
    if ( not exists $data->{opts}->{$id} ) {
        return;
    }
    my $val = $data->{opts}->{$id};
    if ( ref($val) eq 'CODE' ) {
        $val = $val->($data);
    }
    return $val;
}

sub _menuent {
    my $self = shift;
    my $id   = shift;
    if ( not $id ) {
        $@ = "Error: _menuent() requires ID";
        return;
    }
    my $data = $self->data() or die "Error: data not set";
    foreach my $ent ( @{ $data->{menus} } ) {
        if ( $ent->{id} eq $id ) {
            $@ = '';
            return $ent;
        }
    }
    $@ = "No record found for '$id'";
    return;
}

sub menu {
    my $self = shift;
    my $data = $self->data() or die "Error: data not set";
    return map { [ $_->{id}, $_->{desc} ] } @{ $data->{menus} };
}

sub menu_ids {
    my $self = shift;
    my $data = $self->data() or die "Error: data not set";
    return map { $_->{id} } @{ $data->{menus} };
}

# Returns true if enabled
sub menu_enabled {
    my $self = shift;
    my $id   = shift;
    my $data = $self->data() or die "Error: data not set";
    my $rec  = $self->_menuent($id);
    if ( not $rec ) {
        return;
    }
    if ( exists $rec->{prereq} ) {
        foreach my $key ( @{ $rec->{prereq} } ) {
            if ( not $data->{opts}->{$key} ) {
                return;
            }
        }
    }
    return 1;
}

sub menu_desc {
    my $self = shift;
    my $id   = shift or die "Error: command() requires ID";
    my $rec  = $self->_menuent($id);
    if ( ref($rec) ) {
        return $rec->{desc};
    }
    return;
}

sub menu_labels {
    my $self = shift;
    my $data = $self->data() or die "Error: data not set";
    my @ret  = ();
    foreach my $menu ( @{ $data->{menus} } ) {
        my $desc = $menu->{desc};
#        if ( $self->menu_enabled( $menu->{id} ) ) {
#            $desc = '<bold>' . $desc . '</bold>';
#        }
        push @ret, $menu->{id}, $desc;
    }
    return @ret;
}

sub args {
    my $self = shift;
    my $id   = shift or die "Error: command() requires ID";
    my $data = $self->data() or die "Error: data not set";
    my $rec  = $self->_menuent($id);
    if ( $rec and ref( $rec->{args} ) eq 'ARRAY' ) {
        return $rec->{args};
    }
    else {
        return;
    }
}

sub command {
    my $self = shift;
    my $id   = shift or die "Error: command() requires ID";
    my $rec  = $self->_menuent($id);
    if ( defined $rec ) {
        return $rec->{command};
    }
    else {
        return;
    }
}

sub menuhelp {
    my $self = shift;
    my $id   = shift or die "Error: menuhelp() requires ID";
    my $rec  = $self->_menuent($id);
    if ( defined $rec ) {
        return $rec->{help};
    }
    else {
        return;
    }
}

# Given: $argdef, %args
sub map_args {
    my $self = shift;
    my $id = shift;
    my %argin = @_;
    my $argdefs = $self->args($id);
    my @out = ();
    if ( not defined $argdefs ) {
        return;
    }
    foreach my $def ( @{ $argdefs } ) {
        if ( not exists $argin{ $def->{id} } ) {
            next;
        }
        if ( $def->{optional} and not $argin{ $def->{id} } ) {
            next;
        }
        if ( not defined $def->{type} ) {
            if ( $def->{prefix} ) {
                push @out, $def->{prefix};
            }
            push @out, $argin{ $def->{id} };
        } elsif ( $def->{type} eq 'flag' ) {
            if ( $argin{ $def->{id} } =~ m{^(1|y|yes)$} ) {
                push @out, $def->{prefix};
            }
        }
    }
    return @out;
}

sub execute {
    my $self = shift;
}

# validate the config
# note: unsupported nodes will be ignored
sub validate {
    my $self = shift;
    my $data = $self->data() or die "Error: data not set";

    ## Check root level
    if ( not $data->{menus} ) {
        die "Config err: 'menus' must be defined";
    }

    if ( ref( $data->{menus} ) ne 'ARRAY' ) {
        die "Config err: 'menus' must be an array";
    }

    if ( exists $data->{opts} and ref( $data->{opts} ) ne 'HASH' ) {
        die "Config err: 'opts' must be a named-parameter list";
    }

    ## Check menus
    foreach my $menu ( @{ $data->{menus} } ) {
        foreach my $key (qw( id desc command )) {
            if ( not defined $menu->{$key} ) {
                die "Config err: '$key' must be defined";
            }
        }
        if (
            not( ref( $menu->{command} ) eq 'CODE'
                or not ref( $menu->{command} ) )
          )
        {
            die "Config err: 'command' must be string or code ref";
        }
        if ( defined $menu->{prereqs} and ref( $menu->{prereqs} ) ne 'ARRAY' )
        {
            die "Config err: 'menus' must be an array";
        }
        if ( defined $menu->{args} ) {
            if ( ref( $menu->{args} ) ne 'ARRAY' ) {
                die "Config error: 'args' must be a named-parameter list";
            }
            foreach my $arg ( @{ $menu->{args} } ) {
                if ( ref($arg) ne 'HASH' ) {
                    die "Config error: arg must be a named-parameter list";
                }
                foreach my $key (qw( id desc )) {
                    if ( not defined $arg->{$key} ) {
                        die "Config err: arg missing required attribute '$key'";
                    }
                }
            }
        }
    }
    return 1;
}

# Return typescript directory; default to $HOME/menu-audit
sub tsdir {
    my $self = shift;
    return $self->opt('auditdir') || ($ENV{HOME} . '/menu-auditlog');
}

# Given: list of opts names to include in filename
# Return: full path of typescript file
sub tsfile {
    my $self = shift;

    my $timestr = strftime('%Y-%m-%d-%H:%M:%S', localtime);
    my @vals = ();
    foreach my $key ( @_ ) {
        my $val = $self->opt($key);
        push @vals, $val if $val;
    }

    return $self->tsdir . '/' . join('-', @vals, $timestr) . '.log';
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Executive - Executive data structures

=head1 SYNOPSIS

    use App::Executive;

=head1 DESCRIPTION

See the script L<menuexec> for more details.

=head1 LICENSE

Copyright (C) Scott Hardin.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Scott Hardin E<lt>scott@hnsc.deE<gt>

=cut

