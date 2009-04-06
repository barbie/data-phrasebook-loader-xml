#!/usr/bin/perl -w
use strict;
use lib 't';
use BookDB;

use Test::More tests => 7;

# ------------------------------------------------------------------------

my $class = 'Data::Phrasebook';
use_ok $class;

my $file = 't/03phrases.xml';
my $dict = 'BASE';

# ------------------------------------------------------------------------

{
    my $dbh = BookDB->new();

    my $obj = $class->new(
        class  => 'SQL',
        dbh    => $dbh,
		loader => 'XML',
		file   => {
			file => $file,
			ignore_whitespace => 1,
		}
    );
    my $author = 'Lance Parkin';
    my $q = $obj->query( 'find_author', {
            author => \$author,
        });
    isa_ok( $q => 'Data::Phrasebook::SQL::Query' );

    $q->prepare();

    {
        my $count = 0;
        $q->execute();
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq $author;
        }
        is( $count => 7, "7 Parkins" );
        $q->finish();
    }

    {
        my $count = 0;
        $author = 'Paul Magrs';
        $q->execute();
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq $author;
        }
        is( $count => 3, "3 Magrs" );
        $q->finish();
    }

    {
        my $count = 0;
        $q->execute( author => 'Lawrence Miles' );
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq 'Lawrence Miles';
        }
        is( $count => 7, "7 Miles" );
        $q->finish();
    }
}

{
    my $dbh = BookDB->new();

    my $obj = $class->new(
        class  => 'SQL',
        dbh    => $dbh,
		loader => 'XML',
		file   => {
			file => $file,
			ignore_whitespace => 1,
		}
    );
    my $author = 'Lance Parkin';
    my $q = $obj->query( 'find_author' );
    isa_ok( $q => 'Data::Phrasebook::SQL::Query' );

    {
        my $count = 0;
        $q->execute( author => 'Lawrence Miles' );
        while ( my $row = $q->fetchrow_hashref )
        {
            $count++ if $row->{author} eq 'Lawrence Miles';
        }
        is( $count => 7, "7 more Miles" );
    }
}
