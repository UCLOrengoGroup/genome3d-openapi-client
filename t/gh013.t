use Test::More tests => 2;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use Path::Tiny;
use Test::Trap;

use_ok( 'Genome3D::Api::Client' );

my $pdb_dir = path( $FindBin::Bin, '..', 'example_data', 'SUPERFAMILY' );
my $conf_file = path( $FindBin::Bin, '..', 'client_config.superfamily.json' );

my @args = qw/ 
    --resource_id=SUPERFAMILY 
/;
my $mode = $ENV{GENOME3D_TEST_MODE} //= "daily";
if ( $mode ne 'daily' ) {
    diag( "WARNING: test is using mode '$mode' (rather than 'daily')");
}
push @args, "--mode=$mode"; 
push @args, "--conf=$conf_file";

# "update" action is not able to make changes to existing entries

subtest 'update structure annotation (batch with errors)' => sub {
    local @ARGV = @args;
    push @ARGV, "--operation=updateStructurePrediction", "--batch", "--pdbfiles=$pdb_dir";
    diag( "RUNNING: ./genome3d-api " . join( " ", @ARGV ) . "\n" );
    my @r = trap { Genome3D::Api::Client->new_with_options()->run };
    is( $trap->leaveby, 'return', 'leaveby return' );
    like( $trap->stdout, qr/Failed UNIPROT 'B4DXN4': retry \(3 of 3\)/mi, 
        "stdout contains retries for B4DXN4" );
    like( $trap->stdout, qr/Failed UNIPROT 'BADFORMAT': retry \(3 of 3\)/mi, 
        "stdout contains retries for BADFORMAT" );
    like( $trap->stdout, qr/REQUEST:\s+updateStructurePrediction\s+P00520\s+\[200:\s+OK\]/mi, 
        "stdout contains success for P00520" );
    # diag('stdout: ' . $trap->stdout);
    # diag('stderr: ' . $trap->stderr);
};
