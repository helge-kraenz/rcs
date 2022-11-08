package rcs::Controller::Management;

use Mojo::Base 'Mojolicious::Controller';
use rcs::Model::Users;
use Digest::MD5 qw( md5_base64 );

my $DebugInfo = undef;

sub debugInfo
{
  my $self    = shift;
  my $Message = shift || "nowhere";

  return if ! $DebugInfo;

#  $self->log->debug( "--------------" );
  $self->log->debug( ">>>$Message<<<" );
#  $self->log->debug( "Aut: " . ( $self->session('is_auth') || "n/a" ) );
#  $self->log->debug( "Usr: " . ( $self->session('username') || "n/a" ) );
#  $self->log->debug( "Exp: " . ( $self->session('expiration') || "n/a" ) );
#  $self->log->debug( "--------------" );
}

# main {{{
# Render main page - only visible after successful login

sub main
{
  my $self = shift;

  $self->debugInfo( "main start" );

  # Render template "example/welcome.html.ep" with message
  $self->render
  (
    template => 'management/main' ,
    msg      => 'Welcome RCS Management Console' ,
    Role     => $self->session( 'role' ) || 'none' ,
  );
}
# main }}}

# displayLogin {{{
sub displayLogin
{
  my $self = shift;

  $self->debugInfo( "displayLogin start" );

  # If already logged in then direct to home page, if not display login page
  if( $self->alreadyLoggedIn() )
  {
    # If you are using Mojolicious v9.25 and above use this if statement as re-rendering is forbidden
    # Thank you @Paul and @Peter for pointing this out.
    # if($self->session('is_auth')){

    $self->main();

  }
  else
  {
    $self->render
    (
      template      => "management/login" ,
      error_message =>  ""
    );
  }

}
# displayLogin }}}

# validUserCheck {{{
# Check for a valid username/password combination. On success initiates
# a session and hands over control to main routine.
# Display an error message otherwise and redirects to login page.

sub validUserCheck
{
  my $self = shift;

  $self->debugInfo( "validUserCheck start" );

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
  $self->main();
}
# validUserCheck }}}

# alreadyLoggedIn {{{
# Checks if a session is authenticated and returns true.
# If not authenticated shows the login page and returns false.

sub alreadyLoggedIn
{
  my $self = shift;

  $self->debugInfo( "alreadyLoggedIn start" );

  $self->log->debug( "Authenticated(alreadyLoggedIn): " . ($self->session('is_auth')||"") );
  # Checks if session flag (is_auth) is already set and returns true
  return 1 if $self->session('is_auth');


  # If session flag not set re-direct to login page again.
  $self->render
  (
    template      => "management/login" ,
    error_message =>  "You are not logged in, please login to access this website" ,
  );

  return;
}
# alreadyLoggedIn }}}

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
