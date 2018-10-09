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
use JSON::MaybeXS 'JSON';
use OpenAPI::Client;
use Path::Tiny;
use Try::Tiny;
use Test::Trap;
use Term::ANSIColor qw/ /;
use DDP;
use Storable 'dclone';

use Genome3D::Api::Client::Config;
use Genome3D::Api::Client::Types qw/ ServerMode OutputFormat /;

our $VERSION = '0.04';

# this is used to find the root directory of this mojo project
my $API_SCRIPT_FILENAME = 'genome3d-api';

has log_level => ( is => 'rw', default => 3 );
has config => ( is => 'lazy' );
sub _build_config {
  my $self = shift;
  Genome3D::Api::Client::Config->new( $self->conf );
}

has json_out => ( is => 'lazy' );
sub _build_json_out {
  my $self = shift;
  my %args = ( utf8 => 1 );
  $args{ pretty } = 1 if $self->out_format eq 'json_pp';
  return JSON::MaybeXS->new( %args );
}

option mode        => ( is => 'ro',               format => 's',  isa => ServerMode, predicate => 1, default => "daily", doc => "specify the mode for the data source\t(daily|head|release) [daily]",
  order => 10, spacer_after => 1 );

option list        => ( is => 'ro', short => 'l', doc => "list all the available operations",
  order => 20, spacer_after => 1 );

option operation   => ( is => 'ro', short => 'o', format => 's',  predicate => 1, doc => "specify operation (eg 'listResources')",
  order => 30 );
option uniprot_acc => ( is => 'ro', short => 'u', format => 's',  predicate => 1, doc => "specify uniprot identifier (eg 'P00520')",
  order => 30 );
option resource_id => ( is => 'ro', short => 'r', format => 's',  predicate => 1, doc => "specify resource identifier (eg 'SUPERFAMILY')",
  order => 30 );
option pdbfiles    => ( is => 'ro',               format => 's@', predicate => 1, doc => 'specify pdb files for structural prediction',
  order => 30 );
option xmlfile     => ( is => 'ro',               format => 's',  predicate => 1, doc => 'specify xml file for domain prediction',
  order => 30, spacer_after => 1 );

option batch       => ( is => 'ro', short => 'b', doc => "interpret --pdbfiles as directory",
  order => 40);
option pdb_suffix  => ( is => 'ro', default => '.pdb', doc => "only process pdb files with this suffix [.pdb]",
  order => 41);
option retry_on_failure => ( is => 'ro', default => 3, 
  doc => "number of times to retry an operation before quitting [3]",
  order => 41, spacer_after => 1 );
option allowed_consecutive_failures => ( is => 'ro', default => 10, 
  doc => "quit if we encounter this many consecutive errors [10]",
  order => 41 );

option base_path   => ( is => 'ro',               format => 's',  default => '/api', doc => "override the default base path [/api])",
  order => 50 );
option conf        => ( is => 'lazy',             format => 's',  predicate => 1, doc => 'override the default config file [client_config.json]',
  order => 50 );
option host        => ( is => 'lazy',             format => 's',  predicate => 1, doc => "override the default host (eg 'localhost:5000')",
  order => 50, spacer_after => 1 );
option out_format  => ( is => 'lazy',             format => 's',  isa => OutputFormat, default => 'json', doc => 'override the output format ([json_pp] | json)',
  order => 50, hidden => 1 );

option quiet       => ( is => 'ro', short => 'q', doc => "output fewer details",
  order => 80 );
option verbose     => ( is => 'ro', short => 'v', doc => "output more details",
  order => 80 );
option colour      => ( is => 'ro', doc => "make the log reports more colourful",
  order => 80 );

option color       => ( is => 'ro', hidden => 1 );

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

has spec_path      => ( is => 'ro', default => '/openapi.json' );
has auth_path      => ( is => 'ro', default => '/oauth/access_token' );

has spec_url       => ( is => 'lazy' );
has auth_url       => ( is => 'lazy' );
has project_dir    => ( is => 'lazy' );
has openapi        => ( is => 'lazy' );

sub _build_spec_url {
  my $self = shift;
  Mojo::URL->new->scheme( "http" )->host( $self->host )->path( $self->base_path . $self->spec_path );
}

sub _build_auth_url {
  my $self = shift;
  Mojo::URL->new->scheme( "http" )->host( $self->host )->path( $self->base_path . $self->auth_path );
}

sub _build_project_dir {
  my $self = shift;
  my $dir = path('.')->absolute;
  my $log = $self->log_debug( "Searching for project directory... (cwd: $dir)" );
  for (1 .. 3) {
    return $dir if -f $dir->child( $API_SCRIPT_FILENAME );
    $dir = $dir->parent;
    $self->log_debug( "  ... currently in $dir (can't find $API_SCRIPT_FILENAME)" );
  }
  die "! Error: failed to find project directory (looking for the script '$API_SCRIPT_FILENAME')";
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

  if ( $app->verbose ) {
    $app->log_level( $app->log_level - 1 );
  }
  if ( $app->quiet ) {
    $app->log_level( $app->log_level + 1 );
  }

  if ( $app->batch ) {
    die "! Error: uniprot_acc should not be specified when batch mode is set "
        . "(uniprot accession is parsed from the input files in batch mode)"
        if $app->uniprot_acc;

    die "! Error: --pdbfiles is a required parameter for batch mode"
        unless $app->has_pdbfiles;
  }

  my $config = $app->config;

  trap { $app->openapi->validator };
  if ( $trap->die ) {
    my $err = $trap->die;
    die "Error: failed to get valid OpenAPI specification from URL: " . $app->spec_url . " (ERR: $err)";
  }

  if ( $app->list ) {
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

  if ( ! $app->has_operation ) {
    $app->options_short_usage();
    return;
  }

  my $operation = $app->operation;
  my $mode = $app->mode;

  $app->log_info( _kv( "APP.OPENAPI_SPEC", $app->spec_url ) );
  $app->log_info( _kv( "APP.MODE", uc( $mode ) ) );

  $app->_setup_headers();

  my $params_per_uniprot = $app->_build_params_per_uniprot();

  my $consecutive_failures=0;

  UNIPROT: for my $uniprot_acc (sort keys %$params_per_uniprot) {

    my $params = $params_per_uniprot->{ $uniprot_acc };

    my $success = 0;
    my $try_count = 1;
    while (! $success) {
      my $next_uniprot=0;
      try {
        $app->log_debug(sprintf "Sending data for uniprot '%s': try (%d of %d)", $uniprot_acc, $try_count, $app->retry_on_failure );
          
        # create a deep copy to avoid issues with files not being includes on retry
        my $params_copy = dclone $params;
        #$app->log_debug( _kv("params", np($params_copy)) );
        $app->_send_data( $params_copy );
        $success=1;
        $consecutive_failures=0;
      }
      catch {
        # report first line of error message
        my ($message) = map { "$_..." } split(/\n/, $_);        
        $app->log_warn("Caught error while processing UniProt record '$uniprot_acc' ($message)");
        $try_count += 1;
        if ( $try_count <= $app->retry_on_failure ) {
          $app->log_warn(sprintf "Failed UNIPROT '%s': retry (%d of %d)", $uniprot_acc, $try_count, $app->retry_on_failure );
        }
        else {
          $consecutive_failures += 1;
          if ( $consecutive_failures > $app->allowed_consecutive_failures ) {
            my $msg = sprintf("Failed more than %d UniProt records in a row; something horrible has probably happened. I'm quitting. You should leave while you still can.",
              $app->allowed_consecutive_failures);
            $app->log_error($msg);
            die $msg;
          }
          $app->log_error("Skipping UNIPROT '$uniprot_acc'");
          $next_uniprot = 1;
        }
      };
      next UNIPROT if $next_uniprot;
    }
  }
  $app->log_info( "DONE" );
}

sub _setup_headers {
  my $app = shift;

  my $operation = $app->operation;
  my $mode = $app->mode;
  my $api = $app->openapi;
  my $ua = $api->ua;

  if ( $operation =~ /^(add|update|delete)/mi ) {

    if ( $mode eq 'head' or $mode eq 'daily' or $mode eq 'beta' ) {
      # login
      my $client_params = $app->config->as_oauth_hashref;

      # clear any previous events (otherwise it will just append)
      $ua->unsubscribe('start');

      # authenticate, get an access token
      my $tx = $ua->post( $app->auth_url, form => $client_params );
      if ( $tx->res->is_error ) {
        die "! Error: Sorry, there was an error trying to authenticate this client. Please check the details in the config file and try again:\n"
          . "    CONFIG:   " . $app->conf . "\n"
          . "    URL:      " . $app->auth_url . "\n"
          . "    RESPONSE: " . $tx->res->body . "\n"
          ;
      }
      my $access_token = $tx->res->json->{access_token} // '';

      $app->log_debug( "Adding auth token to headers: $access_token" );

      # add the access token to every subsequent request
      $ua->on(start => sub {
        my ($ua, $tx) = @_;
        $tx->req->headers->header( Authorization => "Bearer $access_token" );
      });

      #die "! Error: need to implement login";
    }
    else {
      die "! Error: the operation '$operation' will try to modify the backend database. Only 'read' operations are allowed in server mode '$mode' (try --mode=daily or --mode=head)\n",
    }
  }
}

sub _build_params_per_uniprot {
  my $app = shift;
  my $operation = $app->operation;
  my $config = $app->config;
  
  my %params = (
    operation   => $app->operation,
  );

  $params{resource_id} = $app->resource_id if $app->has_resource_id;
  $params{uniprot_acc} = $app->uniprot_acc if $app->has_uniprot_acc;

  if ( $app->operation =~ /^(add|update|delete)/mi ) {
    if ( ! exists $params{resource_id} ) {
      $params{resource_id} = $config->resource;
      $app->log_debug( _kv( "APP.RESOURCE_FROM_CONFIG", $params{resource_id} ) );
    }
  }

  my %pdbfiles_by_uniprot;
  if( $app->batch ) {
    
    my $pdbdir =  @{ $app->pdbfiles }[0];
    if( ! -d $pdbdir) {
      $app->log_error( "--pdbfiles must be a directory in batch mode" );
      exit(1);
    }

    # all files in this directory matching the suffix *.pdb
    my @pdbfiles = grep { substr($_, -length($app->pdb_suffix)) eq $app->pdb_suffix } 
      path($pdbdir)->children();

    my $file_count = 0;
    # loop over the directory of files and push them all in to a huge hashtable
    foreach my $pdbfile (@pdbfiles) {
      my $document = $pdbfile->slurp();

      if ($document =~ /REMARK\s+GENOME3D\s+UNIPROT_ID\s+(\S+)/) {
        my $uni_acc = $1;
        $pdbfiles_by_uniprot{ $uni_acc } //= [];
        push @{ $pdbfiles_by_uniprot{ $uni_acc } }, "$pdbfile";
      }
      else {
        die "! Error: failed to parse UNIPROT_ID from REMARK comments in file: '$pdbfile'";
      }
      $file_count++;
    }
  }
  else {
    $pdbfiles_by_uniprot{ $app->uniprot_acc } = $app->pdbfiles;
  }

  my %params_per_uniprot;
  foreach my $uniprot_acc (sort keys %pdbfiles_by_uniprot ) {
    my $pdbfiles = $pdbfiles_by_uniprot{ $uniprot_acc };
    $params_per_uniprot{ $uniprot_acc } = { 
      uniprot_acc => $uniprot_acc,
      pdbfiles => [ map { { file => $_ } } @{ $pdbfiles } ],
      ( %params ), 
    };
  }

  return \%params_per_uniprot;
}

sub _send_data {
  my $self = shift;
  my $app = $self;
  my $api = $self->openapi;
  my $operation = $self->operation;
  my $params = shift;
  my %params = %$params;

  if ( $app->has_xmlfile ) {
    my $xml_file = $app->xmlfile;
    $params{ xmlfile } = [ { file => $xml_file } ];
  }

  $app->log_debug( _kv( "REQUEST.OPERATION", $operation ) );
  $app->log_debug( _kv( "REQUEST.DATA", JSON::MaybeXS->new( utf8 => 1, pretty => 0 )->encode( \%params ) ) );

  my $tx = try { $api->$operation( \%params ) }
  catch {
    if ( $_ =~ /can't locate object method/i ) {
      $app->log_error( "ERROR: '$operation' is not a valid operation name (use --list to provide a list of available operations)" );
    }
    else {
      $app->log_error( "ERROR: $_" );
    }
    exit(1);
  };

  $app->log_debug( _kv( "REQUEST.URL", $tx->req->url ) );
  $app->log_trace( _kv( "REQUEST.HEADERS", $tx->req->headers->to_string ) );
  $app->log_debug( _kv( "RESPONSE.CODE", $tx->res->code ) );
  $app->log_debug( _kv( "RESPONSE.MESSAGE", $tx->res->message ) );
  $app->log_trace( _kv( "RESPONSE.BODY", $tx->res->body ) );

  my $uniprot_acc = $params{uniprot_acc} // '<no_uniprot>';

  my $response_text = try { decode_json( $tx->res->body )->{message} } catch { '' };

  my $msg = sprintf( "%-25s %-15s [%s: %s]", 
      $operation, $uniprot_acc, $tx->res->code, $tx->res->message,
    );

  if ( $tx->res->is_error ) {
    $app->log_warn("REQUEST: $msg");
  }
  else {
    $app->log_info("REQUEST: $msg \"$response_text\"");
  }

  if ( $app->batch ) {
    open(my $fhlog, '>>', 'batch.log') or die "Could not open file batch.log $!";
    say $fhlog $params{ uniprot_acc }." : ".$tx->res->code." : ".$tx->res->message;
    close $fhlog;
  }

  if ( $tx->res->is_error ) {
    my $msg = sprintf( "[%d] %s (%s...)\n", $tx->res->code, $tx->res->message, $response_text || $tx->res->body );
    die( "ERROR: $msg" );
  }
  else {
    my $body = decode_json( $tx->res->body );
    if ( ref $body eq 'HASH' ) {
      if ( $app->out_format =~ /^json/i ) {
        $app->log_debug( _kv( "RESPONSE.DATA", $body->{data} ? $app->json_out->encode( $body->{data} ) : '<empty>' ) );
      }
    }
    else {
      $app->log_debug( _kv( "RESPONSE.BODY", substr( $body, 0, 50 ) . ' ...' ) );
    }
    return $body;
  }
}


sub _kv {
  sprintf( "%-30s %s", $_[0], $_[1] // '-' );
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
  my @colours = ('grey5', 'grey10', 'green', 'yellow', 'red');
  my @levels = qw/ trace debug info warn error /;
  if ( $level >= $self->log_level ) {
    $msg = sprintf( "%6s | %s", uc( $levels[$level-1] ), $msg );
    if ( $self->colour || $self->color ) {
      $msg = Term::ANSIColor::colored($msg, $colours[$level-1]);
    }
    printf( "%s %s\n", localtime() . "", $msg );
  }
}

1;
