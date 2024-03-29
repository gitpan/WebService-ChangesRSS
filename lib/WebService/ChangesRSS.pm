package WebService::ChangesRSS;

use strict;
use warnings;
our $VERSION = '0.02';

use Carp;
use LWP::UserAgent;
use HTTP::Date;
use HTTP::Request;
use HTTP::Status;
use XML::RSS;

sub new {
    my ($class, $url) = @_;
    defined($url) or croak "Usage: new(\$url)";
    my $self = bless { url => $url }, $class;
    $self->_init_ua();
    return $self;
}

sub _init_ua {
    my $self = shift;
    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->agent("WebService::ChangesRSS/$VERSION");
}

sub user_agent { shift->{ua} }
sub url { shift->{url} }

sub updated {
    my $self = shift;
    @_ ? $self->{updated} = shift : $self->{updated};
}

sub add_handler {
    my ($self, $sub) = @_;
    defined($sub) and ref($sub) eq 'CODE' or croak "Usage: add_handler(\$subref);";
    push @{$self->{handlers}}, $sub;
}

sub find_new_pings {
    my $self = shift;
    my $simple_api;
    my $now = time;

    if (@_) {
	$simple_api = 1;
	my $interval = shift;
	$self->{updated} = $now - $interval;
    }

    my $request = HTTP::Request->new(GET => $self->url);
    if (defined($self->{updated})) {
	$request->header('If-Modified-Since' => HTTP::Date::time2str($self->{updated}));
    }
    my $response = $self->user_agent->request($request);
    die "Got error in fetching rss - status ", $response->code
	if $response->is_error;

    if ($response->code == RC_NOT_MODIFIED) {
	return $simple_api ? [] : 1;
    }

    my $xml = $response->content();
    my $rss = XML::RSS->new;
    $rss->parse($xml);

    my @items;
    my $old = $self->{updated} || 0;
    my $rss_date = $rss->{channel}->{dc}->{date} || $rss->{channel}->{lastBuildDate};
    $self->{updated} = HTTP::Date::str2time($rss_date) || $now;
    for my $item (@{$rss->{items}}) {
	my $entry_date = $item->{dc}->{date} || $item->{pubDate} ||
	    croak "Cannot determine published date of entry because the entry does not contain dc:date or pubDate element.";
	my $epoch = HTTP::Date::str2time($entry_date);
	my $interval = $self->{updated}  - $epoch;

	# no more new blogs
	last if $old >= $self->{updated} - $interval;
	
	# makes compatibility with WebService::ChangesXml
	$item->{url}  = $item->{link};
	$item->{name} = $item->{title};
	$item->{when} = $epoch;

	if ($simple_api) {
	    push @items, $item;
	} else {
	    for my $handler (@{$self->{handlers}}) {
		$handler->($item->{title}, $item->{link}, $epoch);
	    }
	}
    }
    return $simple_api ? \@items : 1;
}

1;
__END__

=head1 NAME

WebService::ChangesRSS - Do something with updated blogs on Weblogs.Com, using the RSS which contains blog's updated information.

=head1 SYNOPSIS

  use WebService::ChangesRSS;

  # Simple API
  my $changes = WebService::ChangesRSS->new("http://www.weblogs.com/changesRss.xml");
  my $pings   = $changes->find_new_pings(600); # find new blogs updated in 600 seconds

  for my $ping (@$pings) {
      do_something($ping->{url});
  }

  # Event based API
  # do something with new blogs with 300 seconds interval
  
  my $changes = WebService::ChangesRSS->new("http://www.weblogs.com/changesRss.xml");
  $changes->add_handler(\&found_new_ping);

  while (1) {
      $changes->find_new_pings();
      sleep 300;
  }

  sub found_new_ping {
      my($blog_name, $blog_url, $when) = @_;
      do_something($blog_url);
  }

=head1 DESCRIPTION

WebService::ChangesRSS is a module for handling changesRss.xml on Weblogs.com. (or other services that provides information for newly updated blogs with RSS. e.g. http://ping.cocolog-nifty.com/changes.rdf)

This module has same interfaces as L<WebService::ChangesXml>. Please see the document of L<WebService::ChangesXml>.

=head1 NOTICE

In order to handle newly updated blogs, it is necessary that each items have dc:date or pubDate elements which can express updated time of item in the RSS.

=head1 SEE ALSO

L<WebService::ChangesXml>

L<XML::RSS>

http://newhome.weblogs.com/changesRss

http://www.weblogs.com/changesRss.xml

=head1 AUTHOR

Naoya Ito, E<lt>naoya@naoya.dyndns.orgE<gt>

Thanks to Tatsuhiko Miyagawa, author of L<WebService::ChangesXml>. This module is almost its copy. ;)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Naoya Ito

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
