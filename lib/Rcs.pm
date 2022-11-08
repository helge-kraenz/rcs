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
    dsn => 'dbi:Pg:dbname=rcs',
    username => 'rcsss',
    password => 'rcsss',
    options  => { 'pg_enable_utf8' => 1, AutoCommit => 0 },
    helper => 'db',
    });

  # This adds a helper that handles all requests to users table.
  # It requires the database connection recently created as argument.
  $self->helper( usersHandler => sub { state $users = Rcs::Model::Users->new( db => $self->db ) });

  # Normal route to controller
  $r->get(  '/'       )->to( 'Management#displayLogin'   );
  $r->post( '/login'  )->to( 'Management#validUserCheck' );
  $r->any(  '/logout' )->to( 'Management#logout'         );

  # Nothing after this statement is executed when alreadyLoggedIn has failed
  my $authorized = $r->under('/')->to('Management#alreadyLoggedIn');
  $authorized->get( '/user'  )->to( 'Management#userList' );
  $authorized->get( '/user/<:id>/edit'  )->to( 'Management#userEditPage' );
  $authorized->post( '/user/<:id>/edit'  )->to( 'Management#userEditDone' );
  $authorized->get( '/user/<:id>/remove'  )->to( 'Management#userRemove' );
  $authorized->get( '/user/add'  )->to( 'Management#userAddPage' );
  $authorized->post( '/user/add'  )->to( 'Management#userAddDone' );

  $self->log->debug( "-------" );
  $self->log->debug( "STARTED" );

}
# startup }}}


1;
