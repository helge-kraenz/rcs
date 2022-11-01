package rcs::Controller::Management;
use Mojo::Base 'Mojolicious::Controller';

my $DebugInfo = 1;

sub debugInfo
{
  my $self    = shift;
  my $Message = shift || "nowhere";

  return if ! $DebugInfo;

  $self->log->debug( "--------------" );
  $self->log->debug( "Msg: $Message" );
  $self->log->debug( "Aut: " . ( $self->session('is_auth') || "n/a" ) );
  $self->log->debug( "Usr: " . ( $self->session('username') || "n/a" ) );
  $self->log->debug( "Exp: " . ( $self->session('expiration') || "n/a" ) );
  $self->log->debug( "--------------" );
}

# main {{{
# Render main page - only visible after successful login

sub main
{
  my $self = shift;

  debugInfo( $self , "main start" );

  # Render template "example/welcome.html.ep" with message
  $self->render
  (
    template => 'management/main' ,
    msg      => 'Welcome to the Mojolicious real-time web framework!' ,
  );
}
# main }}}

# displayLogin {{{
sub displayLogin
{
  my $self = shift;

  debugInfo( $self , "displayLogin start" );

  # If already logged in then direct to home page, if not display login page
  if( alreadyLoggedIn( $self ) )
  {
    # If you are using Mojolicious v9.25 and above use this if statement as re-rendering is forbidden
    # Thank you @Paul and @Peter for pointing this out.
    # if($self->session('is_auth')){

    main( $self );

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

  debugInfo( $self , "validUserCheck start" );

  # List of registered users
  my %validUsers =
  (
    "JANE" => "welcome123" ,
    "JILL" => "welcome234" ,
    "TOM"  => "welcome345" ,
    "RAJ"  => "test123" ,
    "RAM"  => "digitalocean123" ,
  );

  # Get the user name and password from the page
  my $user     = $self->param( 'username' );
  my $password = $self->param( 'pass' );

  $self->log->debug( "LOGGING" );

  # First check if the user exists
  if( $validUsers{$user} )
  {

    # Validating the password of the registered user
    if( $validUsers{$user} eq $password )
    {

      # Creating session cookies
      $self->session( is_auth    => 1     );    # set the logged_in flag
      $self->session( username   => $user );    # keep a copy of the username
      $self->session( expiration => 600   );    # expire this session in 10 minutes if no activity

      $self->log->debug( "Authenticated: " . $self->session('is_auth') );

      # Re-direct to home page
      main( $self );

      return;
    }
    else
    {

      # If password is incorrect, re-direct to login page and then display appropriate message
      #$self->render(template => "management/login", error_message =>  "Invalid password, please try again");
    }

  }
  else
  {

    # If user does not exist, re-direct to login page and then display appropriate message
    #$self->render(template => "management/login", error_message =>  "You are not a registered user, please get the hell out of here!");

  }

  # Render error page
  $self->render
  (
    template      => "management/login" ,
    error_message => "Wrong login credentials - please try again!" ,
  );

}
# validUserCheck }}}

# alreadyLoggedIn {{{
# Checks if a session is authenticated and returns true.
# If not authenticated shows the login page and returns false.

sub alreadyLoggedIn
{
  my $self = shift;

  debugInfo( $self , "alreadyLoggedIn start" );

  $self->log->debug( "Authenticated(alreadyLoggedIn): " . ($self->session('is_auth')||"") );
  # Checks if session flag (is_auth) is already set and returns true
  return 1 if $self->session('is_auth');

  $self->log->debug( "HUHU01" );


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

  # Redirect to logout page
  $self->render
  (
    template => "management/logout" ,
  );

}
# logout }}}

# users {{{
# Shows the user list

sub users
{
  my $self = shift;

  debugInfo( $self , "users start" );

  if( ! alreadyLoggedIn( $self ) )
  {
    $self->render
    (
      template      => "management/login" ,
      error_message =>  "You are not logged in, fool, please login to access this website" ,
    );
    return;
  }


  # List of registered users
  my %validUsers =
  (
    "JANE" => "welcome123" ,
    "JILL" => "welcome234" ,
    "TOM"  => "welcome345" ,
    "RAJ"  => "test123" ,
    "RAM"  => "digitalocean123" ,
  );

  my $AllUsers = "<tr><th>Name</th><th>Password</th></tr>";

  for my $User ( sort keys %validUsers )
  {
    my $Pass = $validUsers{$User};
    $AllUsers = $AllUsers . "<tr><td>$User</td><td>$Pass</td></tr>";
  }

  # Render users list
  $self->render
  (
    template  => "management/users" ,
    msg       => "List of all users including passwords!" ,
    allusers  => $AllUsers ,
  );

}
# users }}}

1;
