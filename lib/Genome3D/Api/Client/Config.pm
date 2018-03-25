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
has client_secret => ( is => 'ro', lazy => 1, required => 1 );
has client_id     => ( is => 'ro', default => 'contributor' );
has grant_type    => ( is => 'ro', default => 'password' );
has scope         => ( is => 'ro', default => sub { ['write:domain_prediction', 'write:structure_prediction'] } );

sub as_oauth_hashref {
  my $self = shift;
  my %data = map { ( $_ => $self->$_() ) } qw/ username password client_secret client_id grant_type scope /;
  return \%data;
}

1;
