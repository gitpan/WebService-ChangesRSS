use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
    use_ok "WebService::ChangesRSS";
}

my $changes = WebService::ChangesRSS->new("http://ping.cocolog-nifty.com/changes.rdf");

$changes->add_handler(\&found_new_ping);
$changes->updated(time - 10 * 60); # in 10 minutes

$changes->find_new_pings;
my $first = $changes->updated;

$changes->updated(1);
is 1, $changes->updated, "update() set ok";

sub found_new_ping {
    my ($blog_name, $blog_url, $when) = @_;
    like $when, qr/^10\d+/, "when is espoch time: $when";
    is scalar(@_), 3, "argscount is 3";
}
