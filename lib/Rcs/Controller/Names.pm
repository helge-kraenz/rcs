package Rcs::Controller::Names;

use Mojo::Base 'Mojolicious::Controller';
use Rcs::Model::Names;

my $DebugInfo = 1;

sub debugInfo
{
  my $self    = shift;
  my $Message = shift || "nowhere";

  return if ! $DebugInfo;

  $self->log->debug( __PACKAGE__ . ": $Message<<<" );
}

# list {{{
# Shows the list of possible jobs

sub list
{
  my $self  = shift;
  my $Error = shift;

  $self->debugInfo( "list start" );

  # Create work table name if it doesn't exist
  $self->namesHandler->createTable();

  # This helper was created in startup script
  my $Sth = $self->namesHandler->getList();

  # Render users list
  # The renderer will use the statement handle to retrieve the data
  $self->render
  (
    template      => "names/list" ,
    msg           => "List of all possible name updating jobs" ,
    error_message => $Error ,
    sth           => $Sth ,
  );

  $Sth->finish;
  $self->db->rollback();
  $self->debugInfo( "list end" );
}
# list }}}

1;
