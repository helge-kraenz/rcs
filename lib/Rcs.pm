package Rcs;
use Mojo::Base 'Mojolicious';

use Rcs::Model::Users;
use Rcs::Model::Names;

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
  # The database and logger handles are pushed to the classes.
  $self->helper( usersHandler => sub { state $users = Rcs::Model::Users->new( db => $self->db , log => $self->log ) });
  $self->helper( namesHandler => sub { state $names = Rcs::Model::Names->new( db => $self->db , log => $self->log ) });

  # Normal route to controller
  $r->get(  '/'       )->to( 'Management#start'   );
  $r->get(  '/login'  )->to( 'Management#login'   );
  $r->post( '/login'  )->to( 'Management#doLogin' );
  $r->any(  '/logout' )->to( 'Management#logout'  );

  # Nothing after this statement is executed when alreadyLoggedIn has failed
  my $userauth = $r->under( '/'     )->to( 'Management#loggedIn' );
  my $adminauth = $r->under( '/'     )->to( 'Management#admin' );

  # User management related stuff
  $adminauth->get(  '/user'              )->to( 'User#list'   );
  $adminauth->get(  '/user/<:id>/edit'   )->to( 'User#edit'   );
  $adminauth->post( '/user/<:id>/edit'   )->to( 'User#edit'   );
  $adminauth->get(  '/user/<:id>/remove' )->to( 'User#remove' );
  $adminauth->get(  '/user/add'          )->to( 'User#add'    );
  $adminauth->post( '/user/add'          )->to( 'User#add'    );

  # Chemical names related stuff
  #my $authorized = $r->under( '/names'     )->to( 'Management#admin' );
  $userauth->get(  '/names' )->to( 'Names#list'   );

  $self->log->debug( "-------" );
  $self->log->debug( "STARTED" );

}
# startup }}}

1;
