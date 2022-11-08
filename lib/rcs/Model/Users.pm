package rcs::Model::Users;
use Mojo::Base -base;
use Digest::MD5 qw( md5_base64 );

# Initialized during creation from rcs.pm
has 'db';

my $RoleAdmin = "admin";

# Sql queries {{{
my $SelectAllUsers  = "select id, name, role from t_wi_users";
my $GetUserInfo     = "select id, name, password, role from t_wi_users where name = ? ";
my $GetUserInfoById = "select id, name, password, role from t_wi_users where id = ? ";
my $UpdatePassword  = "update t_wi_users set password = ? where id = ?";
my $UpdateRole      = "update t_wi_users set role = ? where id = ?";
my $AddUser         = "insert into t_wi_users ( name, role , password ) values ( ? , ? , ? )";
my $RemoveUser      = "delete from t_wi_users where id = ? ";
# Sql queries }}}

# getList {{{
sub getList
{
  my $self = shift;

  # Execute statement - has to be finished by the caller!
  my $Sth = $self->db->prepare( $SelectAllUsers );
  $Sth->execute();

  # Return statement handle
  $Sth;
}
# getList }}}

# getUserInfo {{{
sub getUserInfo
{
  my $self = shift;
  my $User = shift;

  # Get to information for requested user
  my $Sth = $self->db->prepare( $GetUserInfo );
  $Sth->execute( $User );
  my @UserInfo = $Sth->fetchrow_array();
  $Sth->finish;

  # Return info
  @UserInfo;
}
# getUserInfo }}}

# getUserInfoById {{{
sub getUserInfoById
{
  my $self = shift;
  my $Id   = shift;

  # Get to information for requested user
  my $Sth = $self->db->prepare( $GetUserInfoById );
  $Sth->execute( $Id );
  my @UserInfo = $Sth->fetchrow_array();
  $Sth->finish;

  # Return info
  @UserInfo;
}
# getUserInfoById }}}

# updateUser {{{
sub updateUser
{
  my $self      = shift;
  my $Id        = shift;
  my $Role      = shift || "";
  my $Password1 = shift || "";
  my $Password2 = shift || "";

  # Check for identical passwords
  if( $Password1 ne $Password2 )
  {
    return( 1 , "Passwords do not match" );
  }

  # Get to information for requested user
  my( $DBId , $DBName , $DBPassword , $DBRole ) = $self->getUserInfoById( $Id );

  # Start a transaction
  my $Commit = -1;

  # Trap exceptions
  my $ErrorMessage = eval
  {
    # Update password if requested
    if( $Password1 )
    {
      my $EncryptedPassword = md5_base64( $Password1 );

      if( $EncryptedPassword eq $DBPassword )
      {
        $Commit = 0;
        return( "Password identical to previous one" );
      }

      my $Sth = $self->db->prepare( $UpdatePassword );
      $Sth->execute( $EncryptedPassword , $Id );
      $Commit = 1;
    }

    # Update role if required
    # There is no need to check if the last admin role is removed by this procedure.
    # Because the current user cannot change his own role and the user has to have
    # admin permissions the last admin role cannot be removed using the UI.
    if( $Role && ( $Role ne $DBRole ) )
    {
      my $Sth = $self->db->prepare( $UpdateRole );
      $Sth->execute( $Role , $Id );
      $Commit = 1;
    }
    0;
  };

  if( $@ )
  {
    print STDERR "Error while updateing DB:\n$@\n";
    $Commit = 0;
    $ErrorMessage = "Error while updating user - please check log file";
  }
  if( $ErrorMessage )
  {
    $Commit = 0;
  }

  # Commit changes or roll them back
  $self->db->commit() if $Commit == 1;
  $self->db->rollback();

  # Report status to the caller, 0 for no error, 1 for error
  if( $Commit == -1 )
  {
    return( 0 , "No update needed" );
  }
  elsif( $Commit == 0 )
  {
    return( 1 , $ErrorMessage );
  }

  return( 0 , "" );
}
# updateUser }}}

# addUser {{{
sub addUser
{
  my $self      = shift;
  my $Name      = shift;
  my $Role      = shift;
  my $Password1 = shift;
  my $Password2 = shift;

  # Check for empty user name
  if( ! $Name )
  {
    return( 1 , "No user name given" );
  }

  # Check for empty role
  if( ! $Role )
  {
    return( 1 , "No role given" );
  }

  # Check for empty password
  if( ! $Password1 )
  {
    return( 1 , "No password given" );
  }

  # Check for identical passwords
  if( $Password1 ne $Password2 )
  {
    return( 1 , "Passwords do not match" );
  }

  # Encrypt password
  my $EncryptedPassword = md5_base64( $Password1 );

  # Insert user data
  # Data integrity is covered by database constraints
  my $Sth = $self->db->prepare( $AddUser );
  eval
  {
    $Sth->execute( $Name , $Role , $EncryptedPassword );
  };
  if( $@ )
  {
    $self->db->rollback();

    return( 1 , "Error while adding user $Name to database - please review log" );
  }
  $Sth->finish;


  # Commit changes or roll them back
  $self->db->commit();

  # Report status to the caller, 0 for no error, 1 for error
  return( 0 , "User $Name added" );
}
# addUser }}}

# removeUser {{{
sub removeUser
{
  my $self = shift;
  my $Id   = shift;

  # Get to information for requested user
  my $Sth = $self->db->prepare( $RemoveUser );
  $Sth->execute( $Id );
  $Sth->finish;
}
# removeUser }}}

1;
