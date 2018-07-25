use Test::More tests => 3;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use Path::Tiny;
use Test::Trap;

use_ok( 'Genome3D::Api::Client' );

my $pdb_file = path( $FindBin::Bin, 'data', 'V5QRX7_4_105.pdb' );
my $conf_file = path( $FindBin::Bin, '..', 'client_config.superfamily.json' );

my @args = qw/ 
    --uniprot_acc=V5QRX7 
    --resource_id=SUPERFAMILY 
/;
my $mode = $ENV{GENOME3D_TEST_MODE} //= "daily";
if ( $mode ne 'daily' ) {
    diag( "WARNING: test is using mode '$mode' (rather than 'daily')");
}
push @args, "--mode=$mode"; 
push @args, "--conf=$conf_file";
push @args, "--pdbfiles=$pdb_file";

subtest 'bad operation name provides clear error message' => sub {

    push @args, "--operation=updateStructuralPrediction";

    local @ARGV = @args;

    diag( "RUNNING: ./genome3d-api " . join( " ", @ARGV ) . "\n" );
    my @r = trap { Genome3D::Api::Client->new_with_options()->run };
    is( $trap->leaveby, 'exit', "leaveby exit" );
    unlike( $trap->stderr, qr{is not a valid operation name}i, "clear error message" );
};

subtest 'structure annotation submits okay' => sub {

    push @args, "--operation=updateStructurePrediction";

    local @ARGV = @args;

    diag( "RUNNING: ./genome3d-api " . join( " ", @ARGV ) . "\n" );
    my @r = trap { Genome3D::Api::Client->new_with_options()->run };
    is( $trap->leaveby, 'return', "leaveby return" );
    unlike( $trap->stderr, qr{operation not found}i, "clear error message" );
};

