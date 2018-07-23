use Test::More tests => 3;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use Try::Tiny;
use Test::Trap;

use Data::Dumper;

use_ok( 'Genome3D::Api::Client' );

subtest 'run without args provides usage' => sub {
  local @ARGV = qw/ /;
  my @r = trap { Genome3D::Api::Client->new_with_options()->run };
  is( $trap->leaveby, 'exit', "leaveby okay" );
  like( $trap->stdout, qr{USAGE}, "stdout mentions usage" );
};

subtest 'run with --list provides operation list' => sub {
  local @ARGV = qw/ --list /;
  my @r = trap { Genome3D::Api::Client->new_with_options()->run };
  is( $trap->leaveby, 'return', "leaveby okay" );
  like( $trap->stdout, qr{available operations}i, "stdout mentions 'available operations'" );
};
