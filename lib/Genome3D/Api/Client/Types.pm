package Genome3D::Api::Client::Types;

use Type::Library
  -base,
  -declare => qw(
    ServerMode
    UniprotAcc
    ResourceId
  );
use Type::Utils -all;
use Types::Standard -types;

declare ServerMode,
  as enum( [qw/ head daily release /] );

declare UniprotAcc,
  as Str;

declare ResourceId,
  as Str;
