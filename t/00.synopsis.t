use Test::More;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use Try::Tiny;
use Test::Trap;
use Path::Tiny;
use Data::Dumper;
use DDP;

my $example_data_dir = path( $FindBin::Bin, '..', 'example_data' );
my $sfam_conf_file   = path( $FindBin::Bin, '..', 'client_config_local.json' );

# the following doesn't currently work because the api needs to be mounted as /api
# ./script/api daemon -l http://*:9009
#my $TEST_LOCAL_PORT = 9009;
my $TEST_LOCAL_PORT;

use_ok( 'Genome3D::Api::Client' );


{
  my $c = Genome3D::Api::Client->new();
  isa_ok( $c, 'Genome3D::Api::Client' );
  ok( $c->can('run'), 'can run' );
  is( "" . $c->spec_url, "http://daily.genome3d.eu/api/openapi.json", "spec: default looks okay" );
}

{
  local @ARGV = qw/ --mode=release /;
  my $c = Genome3D::Api::Client->new_with_options();
  is( "" . $c->spec_url, "http://release.genome3d.eu/api/openapi.json", "spec: --mode=release works" );
}

{
  local @ARGV = qw/ --mode=unknown /;
  my @r = trap { Genome3D::Api::Client->new_with_options() };
  is( $trap->exit, 1, "spec: --mode=unknown mode blows up as expected" );
  like( $trap->stderr, qr{unknown}, "stderr error mentions 'unknown'" );
}

{
  local @ARGV = qw/ /;
  my $c = Genome3D::Api::Client->new_with_options( spec_url => 'doesntexist' );
  trap { $c->run };
  like( $trap->die, qr{failed to get valid openapi spec}i, 'unknown host failed with reasonable message' );
}

### Domain Annotations (XML files)

if ( -e $sfam_conf_file ) {

  my $xml_file = $example_data_dir->path( 'SUPERFAMILY', 'B4DXN4.xml' );

  my $base_args = "--mode=daily -r SUPERFAMILY -u B4DXN4 --conf=$sfam_conf_file";

  if ( $TEST_LOCAL_PORT ) {
    $base_args .= " --host=localhost:$TEST_LOCAL_PORT --base_path='' ";
  }

  # UPDATE
  {
    local @ARGV = split( /\s+/, "$base_args -o updateDomainPrediction --xmlfile=$xml_file" );
    my $c = Genome3D::Api::Client->new_with_options();
    my $result = trap { $c->run };
    is( $trap->leaveby, 'return', 'updateDomainPrediction exited okay' );
    unlike( $trap->stderr, qr{ERROR}i, 'updateDomainPrediction STDERR no "error"' );
    like( $trap->stdout, qr{updated 2 entries}i, 'updateDomainPrediction STDOUT looks okay' ); 
    # diag "UPDATE.trap:\n" . np( $trap );
    # diag "UPDATE.stdout:\n" . $trap->stdout;
  } 

  # GET (check update worked)
  {
    local @ARGV = split( /\s+/, "$base_args -o getDomainPrediction" );
    my $c = Genome3D::Api::Client->new_with_options();
    my $result = trap { $c->run };
    is( $trap->leaveby, 'return', 'getDomainPrediction exited okay' );
    unlike( $trap->stderr, qr{ERROR}i, 'getDomainPrediction STDERR no "error"' );
    like( $trap->stdout, qr{retrieved 2 entries}i, 'getDomainPrediction STDOUT looks okay' ); 
    #diag "GET (check update worked):\n" . $trap->stdout;
  }

  # DELETE
  {
    local @ARGV = split( /\s+/, "$base_args -o deleteDomainPrediction" );
    my $c = Genome3D::Api::Client->new_with_options();
    my $result = trap { $c->run };
    is( $trap->leaveby, 'return', 'deleteDomainPrediction exited okay' );
    unlike( $trap->stderr, qr{ERROR}i, 'deleteDomainPrediction STDERR no "error"' );
    like( $trap->stdout, qr{deleted 2 entries}i, 'deleteDomainPrediction STDOUT looks okay' ); 
    # diag "DELETE.trap:\n" . Dumper( $trap );
    # diag "DELETE.stdout:\n" . $trap->stdout;
  }

  # GET (check delete worked)
  {
    local @ARGV = split( /\s+/, "$base_args -o getDomainPrediction" );
    my $c = Genome3D::Api::Client->new_with_options();
    my $result = trap { $c->run };
    is( $trap->leaveby, 'return', 'getDomainPrediction exited okay' );
    unlike( $trap->stderr, qr{ERROR}i, 'getDomainPrediction STDERR does not mention "error"' );
    like( $trap->stdout, qr{retrieved 0 entries}i, 'getDomainPrediction STDOUT looks okay' ); 
    # diag "GET (check delete worked):\n" . $trap->stdout;
  }
}

### Structural Annotations (PDB files)

if ( -e $sfam_conf_file ) {

  my $resource_id = 'SUPERFAMILY';
  my $uniprot_acc = 'P00520';

  my $pdb_dir     = $example_data_dir->path( $resource_id ); 
  my @pdb_files   = $pdb_dir->children( qr/^$uniprot_acc.*?\.pdb$/ );

  my $base_args = "--mode=daily -r $resource_id -u $uniprot_acc --conf=$sfam_conf_file";

  # UPDATE
  {
    local @ARGV = split( /\s+/, "$base_args -o updateStructurePrediction " . join( " ", map { "--pdbfiles=$_" } @pdb_files ) );
    my $c = Genome3D::Api::Client->new_with_options();
    my $result = trap { $c->run };
    is( $trap->leaveby, 'return', 'updateStructurePrediction exited okay' );
    unlike( $trap->stderr, qr{ERROR}i, 'updateStructurePrediction STDERR no "error"' );
    like( $trap->stdout, qr{updated 3 entries}i, 'updateStructurePrediction STDOUT mentions "updated"' ); 
    # diag "UPDATE.trap:\n" . np( $trap );
    # diag "UPDATE.stdout:\n" . $trap->stdout;
  } 

  # GET (check update worked)
  {
    local @ARGV = split( /\s+/, "$base_args -o getStructurePrediction" );
    my $c = Genome3D::Api::Client->new_with_options();
    my $result = trap { $c->run };
    is( $trap->leaveby, 'return', 'getStructurePrediction exited okay' );
    unlike( $trap->stderr, qr{ERROR}i, 'getStructurePrediction STDERR does not mention "error"' );
    like( $trap->stdout, qr{retrieved 3 entries}i, 'getStructurePrediction STDOUT mentions "retrieved"' ); 
    #diag "GET (check update worked):\n" . $trap->stdout;
  }

  # DELETE
  {
    local @ARGV = split( /\s+/, "$base_args -o deleteStructurePrediction" );
    my $c = Genome3D::Api::Client->new_with_options();
    my $result = trap { $c->run };
    is( $trap->leaveby, 'return', 'deleteStructurePrediction exited okay' );
    unlike( $trap->stderr, qr{ERROR}i, 'deleteStructurePrediction STDERR does not mention "error"' );
    like( $trap->stdout, qr{deleted 3 entries}i, 'deleteStructurePrediction STDOUT mentions "deleted"' ); 
    # diag "DELETE.trap:\n" . Dumper( $trap );
    # diag "DELETE.stdout:\n" . $trap->stdout;
  }

  # GET (check delete worked)
  {
    local @ARGV = split( /\s+/, "$base_args -o getStructurePrediction" );
    my $c = Genome3D::Api::Client->new_with_options();
    my $result = trap { $c->run };
    is( $trap->leaveby, 'return', 'getStructurePrediction exited okay' );
    unlike( $trap->stderr, qr{ERROR}i, 'getStructurePrediction STDERR does not mention "error"' );
    like( $trap->stdout, qr{retrieved 0 entries}i, 'getStructurePrediction STDOUT mentions "retrieved"' ); 
    # diag "GET (check delete worked):\n" . $trap->stdout;
  }

}


if ( -e $sfam_conf_file ) {

  ### Structural Annotations (PDB files)

  # UPDATE a structural annotation outside of the dataset (ie the entry doesn't have a sequence) 
  {
    my $resource_id = 'SUPERFAMILY';
    my $uniprot_acc = 'B4DXN4';

    my $pdb_dir     = $example_data_dir->path( $resource_id ); 
    my @pdb_files   = $pdb_dir->children( qr/^$uniprot_acc.*?\.pdb$/ );

    my $base_args = "--mode=daily -r $resource_id -u $uniprot_acc --conf=$sfam_conf_file";
    local @ARGV = split( /\s+/, "$base_args -o updateStructurePrediction " . join( " ", map { "--pdbfiles=$_" } @pdb_files ) );
    my $c = Genome3D::Api::Client->new_with_options();
    my $result = trap { $c->run };
    is( $trap->leaveby, 'return', 'updateStructurePrediction (non core-dataset uniprot entry) exited okay' );
    like( $trap->stderr, qr{\[400\] ERROR}i, 'updateStructurePrediction (non core-dataset uniprot entry) STDERR contained 400 "error"' );
  } 
}

done_testing();
