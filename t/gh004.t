use Test::More tests => 2;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use Path::Tiny;
use Test::Trap;

use_ok( 'Genome3D::Api::Client' );

my $xml_file = path( $FindBin::Bin, 'data', 'GH004.xml' );
my $conf_file = path( $FindBin::Bin, '..', 'client_config.superfamily.json' );

subtest 'update chopping_annotation without error' => sub {
    local @ARGV = qw/ 
        --mode=daily 
        --operation=updateDomainPrediction 
        --uniprot_acc=V5QRX7 
        --resource_id=SUPERFAMILY 
    /;
    push @ARGV, "--conf=$conf_file";
    push @ARGV, "--xmlfile=$xml_file";

    diag( "RUNNING: ./genome3d-api " . join( " ", @ARGV ) . "\n" );
    
    my @r = trap { Genome3D::Api::Client->new_with_options()->run };
    is( $trap->leaveby, 'return', "leaveby return" );
    unlike( $trap->stderr, qr{error}i, "stderr does not mention error" );
    unlike( $trap->stderr, qr{dbi}i,   "stderr does not mention dbi" );
};
