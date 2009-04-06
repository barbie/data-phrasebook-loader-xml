#!/usr/bin/perl -w
use strict;
use lib 't';
use vars qw( $class );

use Test::More tests => 7;

# ------------------------------------------------------------------------

BEGIN {
    $class = 'Data::Phrasebook';
    use_ok $class;
}

my $file = 't/01phrases.xml';
my $dict = 'BASE';

# ------------------------------------------------------------------------

{
    my $obj = $class->new(
		loader => 'XML',
		dict   => $dict
	);
    isa_ok( $obj => $class.'::Plain', "Bare new" );
    $obj->file( $file );
    is( $obj->file() => $file , "Set/get file works");
}

{
    my $obj = $class->new(
		loader => 'XML',
		dict   => $dict,
		file   => {
			file => $file,
			ignore_whitespace => 1,
		}
	);
    isa_ok( $obj => $class.'::Plain', "New with file" );

    {
        my $str = $obj->fetch( 'foo', {
                my => "Iain's",
                place => 'locale',
            });

        is ($str, "Welcome to Iain's world. It is a nice locale.",
            "Fetch matches" );
    }

    {
        $obj->delimiters( qr{ :(\w+) }x );

        my $str = $obj->fetch( 'bar', {
                my => "Bob's",
                place => 'whatever',
            });

        is ($str, "Welcome to Bob's world. It is a nice whatever.",
            "Fetch matches" );
    }
}

{
    my $obj = $class->new(
		loader => 'XML',
		file   => $file,
		dict   => $dict
	);

    {
        my $str = $obj->fetch( 'baz' );

        is ($str, "\n  1\n 2 \n 3\n   ", "Fetch matches with significant whitespace" );
    }
}

