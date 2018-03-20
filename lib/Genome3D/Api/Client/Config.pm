package Genome3D::Api::Client::Config;

use Moo;
use Mojo::JSON qw/ decode_json /;
use Path::Tiny;

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;
  if ( @args == 1 ) {
    my $content = path( "" . $args[0] )->slurp;
    my $data = decode_json( $content );
    return $class->$orig( %$data );
  }
  return $class->$orig( @args );
};

has resource      => ( is => 'ro', lazy => 1, required => 1 );
has username      => ( is => 'ro', lazy => 1, required => 1 );
has password      => ( is => 'ro', lazy => 1, required => 1 );
has client_id     => ( is => 'ro', lazy => 1, required => 1 );
has client_secret => ( is => 'ro', lazy => 1, required => 1 );
has grant_type    => ( is => 'ro', lazy => 1, required => 1 );
has scope         => ( is => 'ro', lazy => 1, required => 1 );

1;
