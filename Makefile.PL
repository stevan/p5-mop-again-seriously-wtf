use v5.20;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'mop',
    VERSION_FROM      => 'lib/mop.pm',
    XSPROTOARG        => '-noprototypes',
    PREREQ_PM         => {},
    LICENSE           => 'perl',
    LIBS              => [''],
    DEFINE            => '',
    test              => {
        TESTS => "t/*.t t/*/*.t"
    }
);