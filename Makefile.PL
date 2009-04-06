use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => 'Data::Phrasebook::Loader::XML',
    VERSION_FROM    => 'lib/Data/Phrasebook/Loader/XML.pm',
    PREREQ_PM       => {
        'Data::Phrasebook' => '0.23',
        'XML::Parser'      => '0',
        'Test::More'       => '0.47',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Data/Phrasebook/Loader/XML.pm',
       AUTHOR        => 'Barbie <barbie@cpan.org>') : ()),
);
