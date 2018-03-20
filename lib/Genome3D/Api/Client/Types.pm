package Genome3D::Client::Types;

use Type::Library
  -base,
  -declare => qw(
    CRUDAction
    UniprotAcc
    ResourceId
  );
use Type::Utils -all;
use Types::Standard -types;

declare CRUDAction,
  as enum [qw/ get add update delete /];

declare UniprotAcc,
  as Str;

declare ResourceId,
  as Str;
