use strict;
use vars qw($VERSION %IRSSI);

use Irssi;

$VERSION = '1.0';
%IRSSI = (
    authors => "Andrew Etches",
    contact => "andrew.etches\@dur.ac.uk",
    name => "replacecalc",
    license => "MIT",
);

sub replace {
    my ($data, $server, $witem) = @_;
    return unless $witem;

    while($data =~ /\@\{([^\}]+)\}\@/){
        my $result = eval($1);
        $data =~ s/\@\{[^\}]+\}\@/$result/;
    }

    $server->command("MSG $witem->{name} $data");
    Irssi::signal_stop();
}

Irssi::signal_add("send text", "replace")
