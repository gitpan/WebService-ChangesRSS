use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'WebService::ChangesRSS',
    VERSION_FROM      => 'lib/WebService/ChangesRSS.pm', # finds $VERSION
    PREREQ_PM         => {
      Test::More => 0.32,
      XML::RSS => 0,
      HTTP::Date => 0,
      LWP::UserAgent => 0,
    }, 
);
