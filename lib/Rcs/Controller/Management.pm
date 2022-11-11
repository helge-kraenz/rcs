package Rcs::Controller::Management;

use Mojo::Base 'Mojolicious::Controller';
use Rcs::Model::Users;
use Digest::MD5 qw( md5_base64 );

my $DebugInfo = 1;

sub debugInfo
{
  my $self    = shift;
  my $Message = shift || "nowhere";

  return if ! $DebugInfo;

  $self->log->debug( "--------------" );
  $self->log->debug( ">>>$Message<<<" );
#  $self->log->debug( "Aut: " . ( $self->session('is_auth') || "n/a" ) );
#  $self->log->debug( "Usr: " . ( $self->session('username') || "n/a" ) );
#  $self->log->debug( "Exp: " . ( $self->session('expiration') || "n/a" ) );
#  $self->log->debug( "--------------" );
}

# start {{{

# Handle request to start page.
# The start page is shown after successful login before the user selectes something
# from menu.
# If not logged in it redirects to login page

sub start
{
  my $self = shift;

  $self->debugInfo( "start start" );

  if( ! $self->session( 'is_auth' ) )
  {
    $self->redirect_to( '/login' );
  }
  else
  {
    $self->render
    (
      template => 'management/main' ,
      msg      => 'Welcome RCS Management Console' ,
      Role     => $self->session( 'role' ) || 'none' ,
    );
  }

  $self->debugInfo( "start end" );
}
# start }}}

# login {{{
sub login
{
  my $self = shift;

  my $Error = $self->param( 'error' ) || "";

  $self->debugInfo( "login start" );

  # If already logged in then direct to home page, if not display login page
  if( $self->session( 'is_auth' ) )
  {
    $self->redirect_to( '/' );
  }
  else
  {
    $self->render
    (
      template      => "management/login" ,
      error_message =>  $Error,
    );
  }

}
# login }}}

# doLogin {{{
# Check for a valid username/password combination. On success initiates
# a session and redirects to main page
# Display an error message otherwise and redirects to login page.

sub doLogin
{
  my $self = shift;

  $self->debugInfo( "doLogin start" );

  # Get the user name and password from the page
  my $User     = $self->param( 'username' );
  my $Password = $self->param( 'password' );

  # Encrypt password
  my $EncryptedPassword = md5_base64( $Password );

  # Get user info from database
  my( $DBId , $DBUser , $DBPassword , $DBRole) = $self->usersHandler->getUserInfo( $User );

  # Check for valid login
  if( ! $DBId || $DBPassword ne $EncryptedPassword )
  {
    $self->log->info( "Failed login for: $User" );
    $self->render
    (
      template      => "management/login" ,
      error_message => "Wrong login credentials for $User - please try again!" ,
    );

    return;
  }

  # Initialize session
  $self->session( is_auth    => 1       );    # set the logged_in flag
  $self->session( username   => $User   );    # keep a copy of the username
  $self->session( role       => $DBRole );    # keep a copy of the username
  $self->session( expiration => 600     );    # expire this session in 10 minutes if no activity

  # Render main page
  $self->redirect_to( '/' );

  $self->debugInfo( "doLogin end" );
}
# doLogin }}}

# loggedIn {{{
# Checks if a session is authenticated and returns true.
# If not authenticated shows the login page and returns false.

sub loggedIn
{
  my $self = shift;

  $self->debugInfo( "loggedIn start" );

  # Return if we are logged in already
  return 1 if $self->session( 'is_auth' );

  # If session flag not set re-direct to login page again.
  $self->redirect_to( '/login' , { error => "You are not logged in, please login to access this website" } );
}
# loggedIn }}}

# admin {{{
# Checks if a session is authenticated and returns true.
# If not authenticated shows the login page and returns false.

sub admin
{
  my $self = shift;

  $self->debugInfo( "admin start" );
  #$self->log->debug( "AUTH:" . $self->session( 'is_auth' ) || "" );
  #$self->log->debug( "AUTH:" . $self->session( 'is_auth' ) || "" );

  # Return if we are logged in already
  return 1 if( $self->session( 'is_auth' ) && ( $self->session( 'role' ) eq 'admin' ) );

  # If session flag not set re-direct to login page again.
  $self->redirect_to( '/' );
}
# admin }}}

# logout {{{
sub logout
{

  my $self = shift;

  # Kill session
  $self->session( expires => 1 );
  $self->session( role => "" );

  # Redirect to logout page
  $self->redirect_to( '/' );
}
# logout }}}

# userList {{{
# Shows the user list

sub userList
{
  my $self  = shift;
  my $Error = shift;

  $self->debugInfo( "userList start" );

  # This helper was created in startup script
  my $Sth = $self->usersHandler->getList();

  # Render users list
  # The renderer will use the statement handle to retrieve the data
  $self->render
  (
    template      => "management/user" ,
    msg           => "List of all users including their roles!" ,
    username      => $self->session( 'username' ) ,
    error_message => $Error ,
    sth           => $Sth ,
  );

  $Sth->finish;
  $self->debugInfo( "user end" );
}
# userList }}}

# userEditPage {{{
# Edits a user

sub userEditPage
{
  my $self    = shift;
  my $Error   = shift || "";
  my $Id      = $self->param( 'id' );

  $self->log->debug( "ID: $Id" );
  $self->debugInfo( "userEditPage start" );

  # Get user info from database
  my( $DBId , $DBUser , $DBPassword , $DBRole ) = $self->usersHandler->getUserInfoById( $Id );

  # Render users edit page
  $self->render
  (
    template      => "management/useredit" ,
    id            => $Id ,
    action        => 'edit' ,
    name          => $DBUser ,
    role          => $DBRole ,
    error_message => $Error ,
  );

  $self->debugInfo( "userEditPage end" );
}
# userEditPage }}}

# userEditDone {{{
# Edits a user

sub userEditDone
{
  my $self      = shift;
  my $Id        = $self->param( 'id' );
  my $User      = $self->param( 'username' );
  my $Role      = $self->param( 'role' );
  my $Password1 = $self->param( 'password1' );
  my $Password2 = $self->param( 'password2' );

  $self->log->debug( "ID: $Id" );
  $self->log->debug( "ROLE: $Role" );
  $self->debugInfo( "userEditDone start" );

  my( $Error , $Message ) = $self->usersHandler->updateUser( $Id , $Role , $Password1 , $Password2 );

  if( $Error )
  {
    $self->userEditPage( $Message );
    return;
  }

  $self->userList( $Message );
}
# userEditDone }}}

# userAddPage {{{
# Adds a user

sub userAddPage
{
  my $self     = shift;
  my $Name     = shift || "";
  my $Role     = shift || "";
  my $Error    = shift || "";

  $self->debugInfo( "userAddPage start" );

  # Render users edit page
  $self->render
  (
    template      => "management/useredit" ,
    id            => undef ,
    action        => 'add' ,
    name          => $Name ,
    role          => $Role ,
    error_message => $Error ,
  );

  $self->debugInfo( "userAddPage end" );
}
# userAddPage }}}

# userAddDone {{{
# Adds a user

sub userAddDone
{
  my $self      = shift;
  my $User      = $self->param( 'username' );
  my $Role      = $self->param( 'role' );
  my $Password1 = $self->param( 'password1' );
  my $Password2 = $self->param( 'password2' );

  $self->debugInfo( "userAddDone start" );

  my( $Error , $Message ) = $self->usersHandler->addUser( $User , $Role , $Password1 , $Password2 );

  if( $Error )
  {
    $self->userAddPage( $User , $Role , $Message );
    return;
  }

  $self->userList( $Message );
}
# userAddDone }}}

# userRemove {{{
# Removes a user

sub userRemove
{
  my $self    = shift;
  my $Id      = $self->param( 'id' );

  $self->log->debug( "ID: $Id" );
  $self->debugInfo( "userRemove start" );

  # Remove user
  $self->usersHandler->removeUser( $Id );

  $self->redirect_to( '/user' );

  $self->debugInfo( "userRemove end" );
}
# userRemove }}}

1;
