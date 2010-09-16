use strict;
use warnings;
use 5.12.1;
use lib '.';
use Tripel;
use Imager;
use Imager::QRCode;

our $VERSION = 0.01;

sub render_qr {
    my ($src, $size) = @_;
    my $qrcode = Imager::QRCode->new(
        size          => $size,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new( 255, 255, 255 ),
        darkcolor     => Imager::Color->new( 0, 0, 0 ),
    );
    my $img = $qrcode->plot($src);
    $img->write( data => \my $data, type => 'png' ) or die "Cannot output image: " . $img->errstr;
    $data;
}

any '/' => sub {
    my $c = shift;
    my $req = $c->req;
    my $size = $req->param("s") || 7;
    my $q = $req->param('q');
    return $c->render_with_fillin_form(
        'index.tt' => {
            q       => $q,
            s       => $size,
            version => $VERSION,
        },
        $req
    );
};
any '/img' => sub {
    my $c = shift;
    my $req = $c->req;
    my $size = $req->param("s") || 7;
    my $text = $req->param('q') // die "missing q";
    my $png = render_qr($text, $size);

    return res( 200,
        [ 'Content-Type' => 'image/png', 'Content-Length' => length($png) ],
        [$png] );
};

to_app();
