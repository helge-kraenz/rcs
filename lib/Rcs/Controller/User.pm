package Rcs::Controller::User;

use Mojo::Base 'Mojolicious::Controller';
use Rcs::Model::Users;
use Digest::MD5 qw( md5_base64 );

my $DebugInfo = 1;

sub debugInfo
{
  my $self    = shift;
  my $Message = shift || "nowhere";

  return if ! $DebugInfo;

  $self->log->debug( __PACKAGE__ . ": $Message<<<" );
}

# list {{{
# Shows the user list

sub list
{
  my $self  = shift;
  my $Error = shift;

  use Data::Dumper;
  $self->debugInfo( "list start" );

  # This helper was created in startup script
  my $Sth = $self->usersHandler->getList();

  # Render users list
  # The renderer will use the statement handle to retrieve the data
  $self->render
  (
    template      => "management/user" ,
    msg           => "List of all users including their roles" ,
    username      => $self->session( 'username' ) ,
    error_message => $Error ,
    sth           => $Sth ,
  );

  $Sth->finish;
  $self->debugInfo( "list end" );
}
# list }}}

# edit {{{
# Show the page allwoing to edit a user

sub edit
{
  my $self      = shift;
  my $Error     = shift || "";
  my $Id        = $self->param( 'id' );
  my $User      = $self->param( 'username' );   # POST only
  my $Role      = $self->param( 'role' );       # POST only
  my $Password1 = $self->param( 'password1' );  # POST only
  my $Password2 = $self->param( 'password2' );  # POST only

  my $Method = $self->req->method;

  $self->debugInfo( "edit start" );

  # If method is GET show only the user info
  if( $Method eq "GET" )
  {
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
  }
  # Apply changes if we have a POST request
  elsif( $Method eq "POST" )
  {
    my( $Error , $Message ) = $self->usersHandler->updateUser( $Id , $Role , $Password1 , $Password2 );

    if( $Error )
    {
      $self->redirect_to( $self->req->url->path , $Message );
      return;
    }

    $self->redirect_to( "/user" );
  }

  $self->debugInfo( "edit end" );
}
# edit }}}

# remove {{{
# Removes a user

sub remove
{
  my $self    = shift;
  my $Id      = $self->param( 'id' );

  $self->debugInfo( "remove start" );

  # Remove user
  $self->usersHandler->removeUser( $Id );

  $self->redirect_to( '/user' );

  $self->debugInfo( "remove end" );
}
# remove }}}

# add {{{
# Adds a user

sub add
{
  my $self      = shift;
  my $User      = $self->param( 'username' );
  my $Role      = $self->param( 'role' );
  my $Password1 = $self->param( 'password1' );
  my $Password2 = $self->param( 'password2' );

  my $Method = $self->req->method;

  $self->debugInfo( "add start" );

  # If method is GET show only the empty form
  if( $Method eq "GET" )
  {
    $self->render
    (
      template      => "management/useredit" ,
      id            => undef ,
      action        => 'add' ,
      name          => "" ,
      role          => "" ,
      error_message => "" ,
    );
  }
  # If method is POST perform changes
  elsif( $Method eq "POST" )
  {
    my( $Error , $Message ) = $self->usersHandler->addUser( $User , $Role , $Password1 , $Password2 );

    if( $Error )
    {
      $self->redirect_to( $self->req->url->path , $Message );
      return;
    }

    $self->redirect_to( "/user" );

  }

  $self->debugInfo( "add end" );
}
# add }}}

1;
