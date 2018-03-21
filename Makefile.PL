#!/usr/bin/env perl
use inc::Module::Install 1.02;

name 'Genome3D-Api-Client';
all_from 'lib/Genome3D/Api/Client.pm';

requires 'OpenAPI::Client';
requires 'Mojo::JSON';
requires 'Moo';
requires 'MooX::Options';
requires 'Path::Tiny';
requires 'Type::Tiny';
requires 'Try::Tiny';
requires 'DDP';

test_requires 'Test::More' => '0.88';

WriteAll;
