requires 'perl', '5.008001';
requires 'YAML';
requires 'Curses::UI';
requires 'Moose';
requires 'Term::ReadKey';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

