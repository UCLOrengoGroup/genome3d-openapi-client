use Test::More tests => 3;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use Path::Tiny;
use Test::Trap;
use Data::Dumper;

use_ok( 'Genome3D::Api::Client' );

my $pdb_dir = path( $FindBin::Bin, 'data' );
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
push @args, "--batch";
push @args, "--pdbfiles=$pdb_dir";

subtest 'structure annotation complains if uniprot acc is specified in batch mode' => sub {
    local @ARGV = @args;

    push @ARGV, "--uniprot_acc=V5QRX7";
    push @ARGV, "--operation=updateStructurePrediction";

    diag( "RUNNING: ./genome3d-api " . join( " ", @ARGV ) . "\n" );
    my @r = trap { Genome3D::Api::Client->new_with_options()->run };

    is( $trap->leaveby, 'die', "leaveby die" );
    like( $trap->die, qr{uniprot_acc should not be specified}i, "clear error message" );
};


subtest 'batch structure annotation submits okay' => sub {

    local @ARGV = (@args, "--operation=updateStructurePrediction");

    diag( "RUNNING: ./genome3d-api " . join( " ", @ARGV ) . "\n" );
    my @r = trap { Genome3D::Api::Client->new_with_options()->run };
    is( $trap->leaveby, 'return', "leaveby return" );
    unlike( $trap->stdout, qr/error/im, "stdout does not contain errors" );
};

