package Genome3D::Api::Client;

=head1 NAME

  Genome3D::Api::Client - client for interaction with Genome3D API

=head1 SYNOPSIS

  $app = Genome3D::Api::Client->new( operation => 'listResources' )
  $app->run;

=head1 AUTHOR

Ian Sillitoe <i.sillitoe@ucl.ac.uk>

=cut

use Moo;
use FindBin;
use MooX::Options;
use Mojo::JSON 'decode_json';
use Mojo::URL;
use OpenAPI::Client;
use Path::Tiny;
use Test::Trap;
use DDP;

use Genome3D::Api::Client::Config;
use Genome3D::Api::Client::Types qw/ ServerMode /;

has log_level => ( is => 'rw', default => 3 );
has config => ( is => 'lazy' );
sub _build_config {
  my $self = shift;
  Genome3D::Api::Client::Config->new( $self->conf );
}

option mode        => ( is => 'ro', isa => ServerMode, format => 's', predicate => 1, default => "daily", doc => "specify the mode for the data source ([daily] | head | release)" );
option conf        => ( is => 'lazy', format => 's', predicate => 1, doc => 'override the default client config file' );
option operation   => ( is => 'ro', short => 'o', format => 's', predicate => 1, doc => "specify operation (eg 'listResources')" );
option uniprot_acc => ( is => 'ro', short => 'u', format => 's', predicate => 1, doc => "specify uniprot identifier (eg 'P00520')" );
option resource_id => ( is => 'ro', short => 'r', format => 's', predicate => 1, doc => "specify resource identifier (eg 'SUPERFAMILY')" );
option xmlfile     => ( is => 'ro', format => 's', predicate => 1, doc => 'specify xml file for domain prediction' );
option pdbfiles    => ( is => 'ro', format => 's@', predicate => 1, doc => 'specify pdb files for structural prediction' );
option host        => ( is => 'lazy', format => 's', predicate => 1, doc => "override the default host (eg 'localhost:5000')" );

sub _build_conf {
  my $self = shift;
  my $dir = $self->project_dir;
  my $f = $dir->child('client_config.json');
  die "! Error: failed to find client configuration file: $f" unless -e $f;
  return $f;
}

sub _build_host {
  my $self = shift;
  return join( '.', $self->mode, 'genome3d.eu' );
}

has spec_path      => ( is => 'ro', default => '/api/openapi.json' );
has spec_url       => ( is => 'lazy' );
has project_dir    => ( is => 'lazy' );
has openapi        => ( is => 'lazy' );

sub _build_spec_url {
  my $self = shift;
  my $host = $self->host;
  my $url = Mojo::URL->new
    ->scheme( "http" )
    ->host( $self->host )
    ->path( $self->spec_path );
  return $url;
}

sub _build_project_dir {
  my $self = shift;
  my $dir = path('.')->absolute;
  for (1 .. 3) {
    return $dir if -f $dir->child('genome3d-api-client');
    $dir = $dir->parent;
  }
  die "! Error: failed to find project directory (looking for the script 'genome3d-api-client')";
}

sub _build_openapi {
  my $self = shift;
  my $host = $self->host;
  my $api = OpenAPI::Client->new( $self->spec_url );
  if ( $host ) {
    $api->base_url->host( $host );
  }
  return $api;
}

sub run {
  my $app = shift;

  my $config = $app->config;

  trap { $app->openapi->validator };
  if ( $trap->die ) {
    die "Error: failed to get valid OpenAPI specification from URL: " . $app->spec_url . " (ERR: $_)";
  }

  if ( ! $app->has_operation ) {
    my $operations = $app->list_all_operation_info;
    print "\n";
    print "Available operations:\n";
    for my $op ( sort keys %$operations ) {
      my $op_spec = $operations->{$op};
      printf "  %-40s %s\n", $op, $op_spec->{summary} // $op->{description} // 'No documentation'; #np( $op_spec );
      if ( scalar @{ $op_spec->{params} } ) {
        printf "    params: " . join( " ", map { sprintf "%s=<%s>", $_->{name}, $_->{type} } @{ $op_spec->{params} } ) . "\n";
      }
      printf "\n"
    }
    print "\n";
    return;
  }

  my $api = $app->openapi;
  my $operation = $app->operation;
  my $mode = $app->mode;

  if ( $operation =~ /^(add|update|delete)/mi ) {
    if ( $mode eq 'head' or $mode eq 'daily' ) {
      # login
      my $resource = $app->config->resource;
      die "! Error: need to implement login";
    }
    else {
      die "! Error: the operation '$operation' will try to modify the backend database. Only 'read' operations are allowed in server mode '$mode' (try --mode=daily or --mode=head)\n",
    }
  }

  my %params = (
    operation   => $operation,
    uniprot_acc => $app->uniprot_acc,
    resource_id => $app->resource_id || $config->resource,
  );

  my $tx = $api->$operation( \%params );
  if ( $tx->res->is_error ) {
    warn sprintf( "[%d] ERROR: %s (%s...)\n", $tx->res->code, $tx->res->message, substr( $tx->res->body, 0, 50 ) );
  }
  else {
    my $data = decode_json( $tx->res->body );
    print np( $data ), "\n";
  }
}

# https://metacpan.org/source/JHTHORSEN/OpenAPI-Client-0.15/lib/OpenAPI/Client.pm#L86

sub list_all_operation_info {
  my $self = shift;
  my $api = $self->openapi;
  my $val = $api->validator;
  my $paths = $val->get( '/paths' );
  my %operationIds;
  for my $path ( keys %$paths ) {
    my $path_parameters = $val->get([paths => $path => 'parameters']) || [];

    for my $http_method ( keys %{$val->get( [ paths => $path ] )} ) {
      next if $http_method =~ /^x-/ or $http_method eq 'parameters';
      my $op_spec = $val->get([paths => $path => $http_method]);
      my $op = $op_spec->{operationId} or next;
      my @rules = (@$path_parameters, @{$op_spec->{parameters} || []});
      $op_spec->{params} = \@rules;
      $operationIds{ $op } = $op_spec;
    }
  }
  return \%operationIds;
}

sub log_error { (shift)->log_msg( 5, @_ ) }
sub log_warn  { (shift)->log_msg( 4, @_ ) }
sub log_info  { (shift)->log_msg( 3, @_ ) }
sub log_debug { (shift)->log_msg( 2, @_ ) }
sub log_trace { (shift)->log_msg( 1, @_ ) }

sub log_msg {
  my ($self, $level, $msg) = @_;
  my @levels = qw/ trace debug info warn error /;
  if ( $level >= $self->log_level ) {
    printf "%s %6s %s\n", localtime() . "", uc( $levels[$level-1] ), $msg;
  }
}

1;
