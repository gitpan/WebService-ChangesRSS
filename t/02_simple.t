use strict;
use Test::More 'no_plan';

BEGIN {
    use_ok "WebService::ChangesRSS";
}

my $changes = WebService::ChangesRSS->new("http://ping.cocolog-nifty.com/changes.rdf");

my $pings = $changes->find_new_pings(60 * 10);
for my $ping (@{$pings}) {
    ok $ping->{url}, "ping has url: $ping->{url}";
    ok $ping->{name}, "ping has name: $ping->{name}";
    ok $ping->{when}, "ping has when: $ping->{when}";
}
