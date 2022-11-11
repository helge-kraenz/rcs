package Rcs::Model::Names;
use Mojo::Base -base;

# Some globals {{{
my $TableUnknown   = "unknown";
my $TableExists    = "exists";
my $TableNotExists = "notexists";
my $Table          = "t_wi_chemicals_names";

# Some globals }}}

# Initialized during creation from Rcs.pm
# Database handler
has 'db';
# Log handler
has 'log';
# Flag indicating whether work table exists
has table => $TableUnknown;
# Holds last (error) message
has message => "";

# Sql queries {{{
my $CheckTable  = "select count(*) from $Table";
my $CreateTable = <<EOTD;
create table $Table
(
  id          serial        primary key            ,
  batch       varchar(20)   not null               ,
  xrn         integer       not null               ,
  mknr        integer       not null               ,
  action      varchar (20)  not null               ,
  old_name    varchar(1000) not null               ,
  new_name    varchar(1000) not null               ,
  source      integer                              ,
  status      integer       not null               ,
  loaded      timestamp     not null default NOW() ,
  executed    timestamp,
  exec_status varchar(20),
  message     varchar(100)
)
EOTD
my $CreateIndex01 = "create index i_wi_cn_batch on $Table( batch )";
my $CreateIndex02 = "create index i_wi_cn_loaded on $Table( loaded )";
my $CreateIndex03 = "create index i_wi_cn_executed on $Table( executed )";
my $CreateIndex04 = "create index i_wi_cn_exec_status on $Table( exec_status )";
my $GetJobs = "select batch, count(*), min(loaded), max(executed), min(exec_status) from $Table group by batch";
my $UpdatePassword  = "update t_wi_users set password = ? where id = ?";
my $UpdateRole      = "update t_wi_users set role = ? where id = ?";
my $AddUser         = "insert into t_wi_users ( name, role , password ) values ( ? , ? , ? )";
my $RemoveUser      = "delete from t_wi_users where id = ? ";
# Sql queries }}}

# createTable {{{
#
# Checks if the work table exists and creates it if it doesn't exist.
# Includes all indexes as well, of course.
# This check is only performed once and all subsequent calls will
# return the response based on the cache
sub createTable
{
  my $self = shift;

  $self->log->debug( "Check table existence cache - current values is '" . $self->table . "'" );
  return 1 if( $self->table eq $TableExists );
  return 0 if( $self->table eq $TableNotExists );

  # Existence of table needs to verified
  $self->log->debug( "Check table existence" );
  my $ReturnValue = eval
  {
    $self->db->do( $CheckTable );
  };

  # Return true if table exists
  if( ! $@ && defined $ReturnValue )
  {
    #$self->log->debug( "$ReturnValue" );
    #$self->log->debug( "$@" );
    $self->log->debug( "Table exists - setting cache accordingly" );
    $self->table( $TableExists );
    $self->db->rollback();
    return 1;
  }
  $self->db->rollback();

  # Create table
  $self->log->debug( "Table does not exist - creating it" );
  eval
  {
    $self->db->do( $CreateTable );
    $self->db->do( $CreateIndex01 );
    $self->db->do( $CreateIndex02 );
    $self->db->do( $CreateIndex03 );
    $self->db->do( $CreateIndex04 );
  };

  # Handle errors and cache that the table didn't exist and could not
  # be created
  if( $@ )
  {
    $self->table( $TableNotExists );
    $self->message( "Could not create work table - review log files for more information" );
    $self->log->error( $@ );
    $self->db->rollback();
    return 0;
  }

  $self->table( $TableExists );
  $self->message( "Work table created" );
  $self->log->debug( "Table created" );
  $self->db->commit();
  return 1;
}
# createTable }}}

# getList {{{
sub getList
{
  my $self = shift;

  # Execute statement - has to be finished by the caller!
  my $Sth = $self->db->prepare( $GetJobs );
  $Sth->execute();

  # Return statement handle
  $Sth;
}
# getList }}}

1;
