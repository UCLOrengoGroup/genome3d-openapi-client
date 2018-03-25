use Test::More tests => 2;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use Try::Tiny;
use Test::Trap;

use Data::Dumper;

use_ok( 'Genome3D::Api::Client' );

subtest 'run without args' => sub {
  local @ARGV = qw/ /;
  my @r = trap { Genome3D::Api::Client->new_with_options()->run };
  is( $trap->leaveby, 'return', "leaveby return" );
  like( $trap->stdout, qr{listResources}, "stdout mentions operation id" );
};
