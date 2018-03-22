use Test::More tests => 8;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../extlib/lib/perl5/";
use Try::Tiny;
use Test::Trap;

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
  is( $trap->exit, 1, "using unknown mode blows up as expected" );
  like( $trap->stderr, qr{unknown}, "stderr error mentions 'unknown'" );
}

{
  local @ARGV = qw/ /;
  my $c = Genome3D::Api::Client->new_with_options( spec_url => 'doesntexist' );
  trap { $c->run };
  like( $trap->die, qr{failed to get valid openapi spec}i, 'unknown host failed with reasonable message' );
}
