use Test::More;
use Test::Mojo;

# Make sure sockets are working
plan skip_all => 'working sockets required for this test!'
  unless Mojo::IOLoop::Server->new->generate_port;    # Test server

use Mojolicious::Lite;

plugin 'ConsoleLogger';

sub setup_log {
  my $self = shift;
  app->log->info('info');
  app->log->debug('debug');
  app->log->error('error');
  app->log->fatal({json => 'structure'});

  $self->session(session => 'value');
  $self->config(config => 'value');
  $self->stash(stash => 'value');
  $self->flash(flash => 'value');
}

get '/json' => sub {
  my $self = shift;
	setup_log($self);
	$self->res->headers->content_type("application/json");
	$self->render(json => 'json text response');
};

get '/json_with_charset' => sub {
  my $self = shift;
	setup_log($self);
	$self->res->headers->content_type("application/json;charset=UTF-8");
	$self->render(json => 'json text response');
};

get '/redirected' => sub {
  my $self = shift;
	setup_log($self);
	$self->redirect_to('/json');
};

get '/:template' => sub {
  my $self = shift;
	setup_log($self);
	$self->render($self->stash->{template});
  # Template not found, generates exception
  $self->rendered;
};


# Tests
my $t = Test::Mojo->new;

# Script tag in dynamic content
$t->get_ok($_)->status_is(200)->element_exists('script')
  ->content_like(
  qr/console\.group\("info"\);\s*console\.log\("info"\);\s*console\.groupEnd\("info"\);/
  )
  ->content_like(
  qr/console\.group\("debug"\);.*?console\.log\("debug"\);.*?console\.groupEnd\("debug"\);/s
  )
  ->content_like(
  qr/console\.group\("error"\);\s*console\.log\("error"\);\s*console\.groupEnd\("error"\);/
  )
  ->content_like(
    qr/console\.group\("fatal"\);\s*console\.log\({"json":"structure"}\);\s*console\.groupEnd\("fatal"\);/
  )
  ->content_like(
  qr/console\.group\("session"\)/
  )
  ->content_like(qr/"session":"value"/)
  ->content_like(
  qr/console\.group\("config"\);\s*console\.log\({"config":"value"}\);\s*console\.groupEnd\("config"\);/
  ) 
  ->content_like(
  qr/console\.group\("stash"\)/
  )
  ->content_like(
  qr/"stash":"value"/
  )
  # No hidden stash values
  ->content_unlike(
  qr/"mojo\./
  )
  
  for qw| /normal |; #/exception |;

# No script tag in static content
$t->get_ok('/mojo/prettify/run_prettify.js')->status_is(200)->element_exists(':not(script)');

# No script tag in json response
$t->get_ok('/json')->status_is(200)->content_is('"json text response"');

# No script tag in json response with charset in content-type
$t->get_ok('/json_with_charset')->status_is(200)->content_is('"json text response"');

$t->ua->max_redirects(0);
# No need to display console log during redirection
$t->get_ok('/redirected')->status_is(302)->content_is('');
$t->ua->max_redirects(1);

done_testing;
__DATA__

@@ normal.html.ep
<html>
<body>
</body>
</html>
