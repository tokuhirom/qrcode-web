use strict;
use warnings;
use 5.12.1;
use Imager;
use Imager::QRCode;
use Plack::Request;
use Text::Xslate;
use Data::Section::Simple qw/get_data_section/;
use HTML::FillInForm::Lite;
use Router::Simple::Sinatraish;
use Plack::Response;

my $xslate = Text::Xslate->new(syntax => 'TTerse');

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
    my $req = shift;
    my $size = $req->param("s") || 7;
    my $q = $req->param('q');
    my $tmpl = get_data_section('index.tx');
    my $html = $xslate->render_string( $tmpl,
        { q => $q, s => $size, version => $VERSION } );
    $html = HTML::FillInForm::Lite->fill( \$html,  $req );
    return Plack::Response->new(
        200,
        [
            'Content-Type'   => 'text/html; charset=utf-8',
            'Content-Length' => length($html)
        ],
        [$html]
    );
};
any '/img' => sub {
    my $req = shift;
    my $size = $req->param("s") || 7;
    my $text = $req->param('q') // die "missing q";
    my $png = render_qr($text, $size);

    return Plack::Response->new( 200,
        [ 'Content-Type' => 'image/png', 'Content-Length' => length($png) ],
        [$png] );
};

my $app = sub {
    my $env = shift;

    if ( my $route = __PACKAGE__->router->match($env) ) {
        my $req = Plack::Request->new($env);
        my $res = $route->{code}->($req);
        return $res->finalize();
    }
    else {
        my $content = 'not found';
        return [404, ['Content-Length' => length($content)], [$content]];
    }
};

__DATA__

@@ index.tx
<!doctype html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="Content-Style-Type" content="text/css" />
    <meta http-equiv="content-script-type" content="text/javascript" />
    <title>qrcode server - [% version %]</title>
    <style>
        #Container {
            text-align: center;
            width: 640px;
            margin: auto;
        }
        #content {
            text-align: left;
        }
        footer {
            text-align: left;
            font-size: xx-small;
        }
    </style>
</head>
<body>
    <div id="Container">
        <h1>qrcode server - [% version %]</h1>
        <div id="content">
            <form action="/" method="get">
                <select name="s">
                <option value="1">1</option>
                <option value="2">2</option>
                <option value="3">3</option>
                <option value="4">4</option>
                <option value="5">5</option>
                <option value="6">6</option>
                <option value="7" selected="selected">7</option>
                <option value="8">8</option>
                <option value="9">9</option>
                <option value="10">10</option>
                </select><br />
                <textarea name="q" rows="5" cols="50"></textarea>
                <input type="submit" value="render" />
            </form>
            <a href="javascript:location.href=location.href+'?q='+encodeURIComponent(location.href)">bookmarklet</a>

            [% IF q %]
                <div><img src="/img?q=[% q | uri %]&amp;s=[% s | uri %]" /><br />[% q %]</div>
            [% END %]
        </div>
        <hr />
        <footer>
            This is qrcode rendering server.
        </footer>
    </div>
</body>
</html>

