package rcs;
use Mojo::Base 'Mojolicious';

# startup {{{
# This method will run once at server start
sub startup
{
  my $self = shift;

  # Load configuration from hash returned by config file
  my $config = $self->plugin( 'Config' );

  # Configure the application
  $self->secrets( $config->{secrets} );

  # Router
  my $r = $self->routes;

  $self->plugin( 'database', {
    dsn => 'dbi:Pg:dbname=rcs',
    username => 'rcsss',
    password => 'rcsss',
    options  => { 'pg_enable_utf8' => 1, AutoCommit => 0 },
    helper => 'db',
    });

  $self->log->debug( "STARTUP 1" );

  # Normal route to controller
  $r->get(  '/'       )->to( 'Management#displayLogin'   );
  $r->post( '/login'  )->to( 'Management#validUserCheck' );
  $r->any(  '/logout' )->to( 'Management#logout'         );
  $r->get( '/users'  )->to( 'Management#users' );

  # Nothing after this statement is executed when alreadyLoggedIn has failed
  my $authorized = $r->under('/')->to('Management#alreadyLoggedIn');

  $self->log->debug( "STARTUP 2" );

}
# startup }}}

1;
