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
use Genome3D::Api::Client::Config;
use Mojo::JSON 'decode_json';
use Mojo::URL;
use OpenAPI::Client;
use Path::Tiny;
use DDP;

has config => ( is => 'lazy' );
sub _build_config {
  my $self = shift;
  Genome3D::Api::Client::Config->new( $self->conf );
}

option conf        => ( is => 'ro', format => 's', predicate => 1, doc => 'override the default client config file', default => "$FindBin::Bin/client_config.json"  );
option operation   => ( is => 'ro', short => 'o', format => 's', predicate => 1, doc => "specify operation (eg 'listResources')" );
option uniprot_acc => ( is => 'ro', short => 'u', format => 's', predicate => 1, doc => "specify uniprot identifier (eg 'P00520')" );
option resource_id => ( is => 'ro', short => 'r', format => 's', predicate => 1, doc => "specify resource identifier (eg 'SUPERFAMILY')" );
option host        => ( is => 'ro', format => 's', predicate => 1, doc => "override the default host (eg 'localhost:5000')", default => 'head.genome3d.eu' );
option xml_file    => ( is => 'ro', format => 's', predicate => 1, doc => 'specify xml file for domain prediction' );
option pdb_file    => ( is => 'ro', format => 's', predicate => 1, doc => 'specify pdb file for structural prediction' );

has spec_path      => ( is => 'ro', default => '/api/openapi.json' );
has spec_url       => ( is => 'lazy' );
sub _build_spec_url {
  my $self = shift;
  my $host = $self->host;
  my $url = Mojo::URL->new
    ->scheme( "http" )
    ->host( $self->host )
    ->path( $self->spec_path );
  return $url;
}

has openapi        => ( is => 'lazy' );
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

  if ( ! $app->has_operation ) {
    my $operations = $app->list_all_operations;
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
    exit(0);
  }

  my $api = $app->openapi;

  my $operation = $app->operation;

  my %params = (
    operation   => $operation,
    uniprot_acc => $app->uniprot,
    resource_id => $app->resource || $config->resource,
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

sub list_all_operations {
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

1;
