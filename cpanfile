requires 'perl', '5.008001';
requires 'YAML';
requires 'Curses::UI';
requires 'Moose';
requires 'Term::Readkey';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

