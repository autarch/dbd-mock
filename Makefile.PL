use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'DBD::Mock',
    VERSION_FROM      => 'VERSION',
    PREREQ_PM         => {
        DBI => 1.30,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBD/Mock.pm', # retrieve abstract from module
       AUTHOR         => 'Chris Winters <chris@cwinters.com>') : ()),
);
