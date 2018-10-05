use Test::More tests => 4;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use Path::Tiny;
use Test::Trap;

use_ok( 'Genome3D::Api::Client' );

my $pdb_dir = path( $FindBin::Bin, 'data' );
my $conf_file = path( $FindBin::Bin, '..', 'client_config.superfamily.json' );

my @args = qw/ 
    --resource_id=SUPERFAMILY 
    --uniprot_acc=V5QRX7
/;
my $mode = $ENV{GENOME3D_TEST_MODE} //= "daily";
if ( $mode ne 'daily' ) {
    diag( "WARNING: test is using mode '$mode' (rather than 'daily')");
}
push @args, "--mode=$mode"; 
push @args, "--conf=$conf_file";

# "update" action is not able to make changes to existing entries

subtest 'delete structure annotation (may not exist)' => sub {
    local @ARGV = @args;
    push @ARGV, "--operation=deleteStructurePrediction";
    diag( "RUNNING: ./genome3d-api " . join( " ", @ARGV ) . "\n" );
    my @r = trap { Genome3D::Api::Client->new_with_options()->run };
    is( $trap->leaveby, 'return' );
};

subtest 'create structure annotation' => sub {
    local @ARGV = @args;
    push @ARGV, "--operation=updateStructurePrediction";
    diag( "RUNNING: ./genome3d-api " . join( " ", @ARGV ) . "\n" );
    my @r = trap { Genome3D::Api::Client->new_with_options()->run };
    is( $trap->leaveby, 'return' );
};

subtest 'update structure annotation' => sub {
    local @ARGV = @args;
    push @ARGV, "--operation=updateStructurePrediction";
    diag( "RUNNING: ./genome3d-api " . join( " ", @ARGV ) . "\n" );
    my @r = trap { Genome3D::Api::Client->new_with_options()->run };
    is( $trap->leaveby, 'return' );
};
