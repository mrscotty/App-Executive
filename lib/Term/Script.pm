package Term::Script;

# This is a simple wrapper around the 'script' utility.

use Moose;

has 'file' => (
    is => 'rw',
);

foreach my $opt ( qw( append quiet timestamping ) ) {
    has $opt => (
        is => 'rw',
    );
}

sub run {
    my $self = shift;
    my @opts = ();

    push @opts, '-a' if $self->append();
    push @opts, '-q' if $self->quiet();
    push @opts, '-r' if $self->timestamping();

    system('script', @opts, $self->{'file'}, @_);
}
1;

