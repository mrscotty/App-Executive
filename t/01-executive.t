#!/usr/bin/perl
#

use strict;
use warnings;

use Test::More;
use Data::Dumper;
use App::Executive;

my $menucfg = [
    {
        id      => 'test1',
        desc    => 'Test menu 1',
        command => sub {
            my $cfg  = shift;
            my %args = @_;
            foreach my $key ( keys %args ) {
                $cfg->{$key} = $args{$key};
            }
        },
        args => [
            {
                id   => 'custref',
                desc => 'Customer Reference',
            },
            {
                id       => 'gituser',
                desc     => 'Full User (for audit log)',
                optional => 1,
            },
            {
                id       => 'gitmail',
                desc     => 'Email Address (for audit log)',
                optional => 1,
            },
        ],
    },
    {
        id      => 'test2',
        desc    => 'Test menu 2',
        command => 'test2.sh',
        prereq  => [qw( custref )],
        args    => [
            {
                id   => 'custref',
                desc => 'Customer Reference',
            },
            {
                id       => 'param1',
                desc     => 'Parameter 1',
                prefix   => '--param1',
                optional => 1,
            },
            {
                id       => 'test2_verbose',
                desc     => 'Verbose output?',
                optional => 1,
                prefix   => '--verbose',
                type     => 'flag',
            },
        ],
    },
    {
        id      => 'test3',
        desc    => 'Test menu 3',
        command => 'test3.sh',
        prereq  => [qw( gituser gitmail )],
    },
    {
        id      => 'test4',
        desc    => 'Test menu 4',
        command => 'test4.sh',
    },
    {
        id      => 'test5',
        desc    => 'Test menu 5',
        command => 'test5.sh',
    },

];

my $cfg = {
    menus => $menucfg,
    opts  => {

        #        custref => 'REQ123',
        script  => 1,
        gituser => 'Joe Blow',
        gitmail => 'joe@example.com',
    },
};

my $app = App::Executive->new( { data => $cfg } );
isa_ok( $app, 'App::Executive' );

my @menu = $app->menu();
is_deeply(
    \@menu,
    [
        [ 'test1', 'Test menu 1' ],
        [ 'test2', 'Test menu 2' ],
        [ 'test3', 'Test menu 3' ],
        [ 'test4', 'Test menu 4' ],
        [ 'test5', 'Test menu 5' ],
    ],
    '$app->menu()'
);

is_deeply(
    [ $app->menu_ids() ],
    [ 'test1', 'test2', 'test3', 'test4', 'test5' ],
    '$app->menu_ids()'
);

{
    #my $pre = '<bold>'; my $post = '</bold>';
    my $pre  = '';
    my $post = '';
    is_deeply(
        [ $app->menu_labels() ],
        [
            'test1', $pre . 'Test menu 1' . $post,
            'test2', 'Test menu 2',
            'test3', $pre . 'Test menu 3' . $post,
            'test4', $pre . 'Test menu 4' . $post,
            'test5', $pre . 'Test menu 5' . $post
        ],
        '$app->menu_labels()'
    );
}

is_deeply(
    $app->_menuent('test5'),
    { id => 'test5', desc => 'Test menu 5', command => 'test5.sh' },
    '$app->_menuent()'
);
is( $app->_menuent(), undef, '$app->_menuent() with undef value' );
is( $@, 'Error: _menuent() requires ID', '$@ of _menuent() with undef value' );
is( $app->_menuent('testZ'), undef, '$app->_menuent() with unknown value' );

is( $app->command('test2'), 'test2.sh', '$app->command()' );
is( $app->command('testZ'), undef,      '$app->command() with unknown value' );
is( $app->menu_enabled(),   undef,      '$app->_menuent() with undef value' );

my @args = $app->map_args(
    'test2',
    'custref'       => 'CHG123',
    'param1'        => 'p1-val',
    'test2_verbose' => 'y'
);
is_deeply(
    \@args,
    [ 'CHG123', '--param1', 'p1-val', '--verbose' ],
    'arg test - all'
) or diag "args: ", join( ', ', @args );

@args = $app->map_args(
    'test2',
    'test2_verbose' => 'yup'
);
is_deeply(
    \@args,
    [ ],
    'arg test - bad flag'
) or diag "args: ", join( ', ', @args );

done_testing;

