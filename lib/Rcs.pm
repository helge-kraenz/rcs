package Rcs;
use Mojo::Base 'Mojolicious';

use Rcs::Model::Users;

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

  # This initializes a database connection and stored the connection handle in
  # helper 'db'
  $self->plugin( 'database', {
    dsn      => 'dbi:Pg:dbname=rcs',
    username => 'rcsss',
    password => 'rcsss',
    options  => { 'pg_enable_utf8' => 1, AutoCommit => 0 },
    helper   => 'db',
  } );

  # This adds a helper that handles all requests to users table.
  # It requires the database connection recently created as argument.
  $self->helper( usersHandler => sub { state $users = Rcs::Model::Users->new( db => $self->db ) });

  # Normal route to controller
  $r->get(  '/'       )->to( 'Management#start'   );
  $r->get(  '/login'  )->to( 'Management#login'   );
  $r->post( '/login'  )->to( 'Management#doLogin' );
  $r->any(  '/logout' )->to( 'Management#logout'  );

  # Nothing after this statement is executed when alreadyLoggedIn has failed
  my $authorized = $r->under('/')->to('Management#loggedIn');
  $authorized->get(  '/user'              )->to( 'User#list'   );
  $authorized->get(  '/user/<:id>/edit'   )->to( 'User#edit'   );
  $authorized->post( '/user/<:id>/edit'   )->to( 'User#edit'   );
  $authorized->get(  '/user/<:id>/remove' )->to( 'User#remove' );
  $authorized->get(  '/user/add'          )->to( 'User#add'    );
  $authorized->post( '/user/add'          )->to( 'User#add'    );

  $self->log->debug( "-------" );
  $self->log->debug( "STARTED" );

}
# startup }}}


1;
