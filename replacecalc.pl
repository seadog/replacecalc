use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
use URI::Escape;
use LWP::UserAgent;
use JSON;

$VERSION = '1.0';
%IRSSI = (
    authors => "Andrew Etches",
    contact => "andrew.etches\@dur.ac.uk",
    name => "replacecalc",
    license => "MIT",
);

my $agent = LWP::UserAgent->new(
    agent => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.19 (KHTML, like Gecko) Chrome/18.0.1025.142 Safari/535.19",
);

sub replace {
    my ($data, $server, $witem) = @_;
    return unless $witem;

    while($data =~ /\@\{([^\}]+)\}\@/){
        my $url = "http://www.google.com/ig/calculator?num=1&q=".uri_escape($1);
        my $response = $agent->get($url);
        my $json = new JSON;
        my $text = $response->content;
        $text =~ s/([a-z]+)\:/\"$1\"\:/g;
        my $jsontext = $json->decode($text);

        my $result = $jsontext->{rhs};
        $data =~ s/\@\{[^\}]+\}\@/$result/;
    }

    $server->command("MSG $witem->{name} $data");
    Irssi::signal_stop();
}

Irssi::signal_add("send text", "replace")
