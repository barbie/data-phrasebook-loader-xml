package Data::Phrasebook::Loader::XML;
use strict;
use warnings FATAL => 'all';
use Carp qw( croak );
use base qw( Data::Phrasebook::Loader::Base Data::Phrasebook::Debug );
use XML::Parser;
use IO::File;

our $VERSION = '0.04';

=head1 NAME

Data::Phrasebook::Loader::XML - Absract your phrases with XML.

=head1 SYNOPSIS

    use Data::Phrasebook;

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'XML',
        file   => 'phrases.xml',
    );

  OR

    my $q = Data::Phrasebook->new(
        class  => 'Fnerk',
        loader => 'XML',
        file   => {
            file => 'phrases.xml',
            ignore_whitespace => 1,
        }
    );

    $q->delimiters( qr{ \[% \s* (\w+) \s* %\] }x );
    my $phrase = $q->fetch($keyword);

=head1 ABSTRACT

This module provides a loader class for phrasebook implementations using XML.

=head1 DESCRIPTION

This class loader implements phrasebook patterns using XML. 

Phrases can be contained within one or more dictionaries, with each phrase 
accessible via a unique key. Phrases may contain placeholders, please see 
L<Data::Phrasebook> for an explanation of how to use these. Groups of phrases
are kept in a dictionary. The first dictionary is used as the default, unless 
a specific dictionary is requested.

In this implementation, the dictionaries and phrases are implemented with an
XML document. This document is the same as implement by L<Class::Phrasebook>.

The XML document type definition is as followed:

 <?xml version="1.0"?>
 <!DOCTYPE phrasebook [
	       <!ELEMENT phrasebook (dictionary)*>              
	       <!ELEMENT dictionary (phrase)*>
               <!ATTLIST dictionary name CDATA #REQUIRED>
               <!ELEMENT phrase (#PCDATA)>
               <!ATTLIST phrase name CDATA #REQUIRED>
 ]>

An example XML file:

 <?xml version="1.0"?>
 <!DOCTYPE phrasebook [
	       <!ELEMENT phrasebook (dictionary)*>              
	       <!ELEMENT dictionary (phrase)*>
               <!ATTLIST dictionary name CDATA #REQUIRED>
               <!ELEMENT phrase (#PCDATA)>
               <!ATTLIST phrase name CDATA #REQUIRED>
 ]>
 
 <phrasebook>
 <dictionary name="EN">
   <phrase name="HELLO_WORLD">Hello World!!!</phrase>
   <phrase name="THE_HOUR">The time now is $hour.</phrase>
   <phrase name="ADDITION">add $a and $b and you get $c</phrase>
   <phrase name="THE_AUTHOR">Barbie</phrase>
 </dictionary>

 <dictionary name="FR">
   <phrase name="HELLO_WORLD">Bonjour le Monde!!!</phrase>
   <phrase name="THE_HOUR">Il est maintenant $hour.</phrase>
   <phrase name="ADDITION">$a + $b = $c</phrase>
   <phrase name="THE_AUTHOR">Barbie</phrase>
 </dictionary>

 <dictionary name="NL">
   <phrase name="HELLO_WORLD">Hallo Werld!!!</phrase>
   <phrase name="THE_HOUR">Het is nu $hour.</phrase>
   <phrase name="ADDITION">$a + $b = $c</phrase>
   <phrase name="THE_AUTHOR">Barbie</phrase>
 </dictionary>
 </phrasebook>

Note that, unlike L<Class::Phrasebook>, this implementation does not search 
the default dictionary if a phrase is not found in the specified dictionary. 
This may change in the future.

Each phrase should have a unique name within a dictionary, which is then used 
as a reference key. Within the phrase text placeholders can be used, which are
then replaced with the appropriate values once the get() method is called.

The parameter 'ignore_whitespace', will remove any extra whitespace from the
phrase. This includes leading and trailing whitespace. Whitespace around a
newline, including the newline, is replace with a single space.

=head1 INHERITANCE

L<Data::Phrasebook::Loader::XML> inherits from the base class
L<Data::Phrasebook::Loader::Base>.
See that module for other available methods and documentation.

=head1 METHODS

=head2 load

Given a C<file>, load it. C<file> must contain valid XML.

   $loader->load( $file, $dict );

This method is used internally by L<Data::Phrasebook::Generic>'s
C<data> method, to initialise the data store.

=cut

my $phrases;

sub load
{
    my ($class, $file, $dict) = @_;
	my $ignore_whitespace = 0;
	if(ref $file eq 'HASH') {
		$ignore_whitespace = $file->{ignore_whitespace};
		$file = $file->{file};
	}
    croak "No file given as argument!" unless defined $file;

	my $read_on = 1;
	my $default_read = 0;
	my ($phrase_name,$phrase_value);

	# create the XML parser object
    my $parser = XML::Parser->new(ErrorContext => 2);
    $parser->setHandlers(
        Start => sub {
            my $expat = shift;
            my $element = shift;
            my %attributes = (@_);	    
	    
            # deal with the dictionary element
            if ($element =~ /dictionary/) {
				my $name = $attributes{name};
                croak('The dictionary element must have the name attribute')
					unless (defined($name));

				# if the default was already read, and the dictionary name
				# is not the requested one, we should not read on.
                $read_on = ($default_read && $name ne $dict) ? 0 : 1;
            }

            # deal with the phrase element
            if ($element =~ /^phrase$/) {
                $phrase_name = $attributes{name};
                croak('The phrase element must have the name attribute')
					unless (defined($phrase_name));
            }

			$phrase_value = '';	# ensure a clean phrase
        }, # of Start
	
        End => sub {
            my $expat = shift;
            my $element = shift;
			if ($element =~ /^dictionary$/i) {
				$default_read = 1;
			}
	    
			if ($element =~ /^phrase$/i) {
				if ($read_on) {
					if($ignore_whitespace) {
						$phrase_value =~ s/^\s+//;
						$phrase_value =~ s/\s+$//;
						$phrase_value =~ s/\s*\n\s*/ /gs;
					}
					$phrases->{$phrase_name} = $phrase_value;
					$phrase_value = '';
				}
            }
        }, # of End
	
        Char => sub {
            my $expat = shift;
            my $string = shift;

			# if $read_on flag is true and the string is not empty we set the 
			# value of the phrase.
			if ($read_on && length($string)) {
				$phrase_value .= $string;
			}		
        } # of Char
    ); # of the parser setHandlers class

    # open the xml file as a locked file and parse it
    my $fh = IO::File->new($file);
    croak("Could not open $file for reading.")	unless ($fh);

    eval { $parser->parse($fh) }; # eval used, due to the fact that the parse 
                                  # function dies when it encounters a parsing
								  # error.
    croak("Could not parse the file [$file]: ".$@)	if ($@);

    $class->{phrases} = $phrases;
}
	
=head2 get

Returns the phrase stored in the phrasebook, for a given keyword.

   my $value = $loader->get( $key );

=cut

sub get {
	my ($class, $key) = @_;
	return $class->{phrases}{$key};
}

1;

__END__

=head1 SEE ALSO

L<Data::Phrasebook>.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/). However, it would help greatly if you are 
able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 LICENCE AND COPYRIGHT

  Copyright (C) 2004-2005 Barbie for Miss Barbell Productions.

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.

The full text of the licences can be found in the F<Artistic> and
F<COPYING> files included with this module, or in L<perlartistic> and
L<perlgpl> in Perl 5.8.1 or later.

=cut
