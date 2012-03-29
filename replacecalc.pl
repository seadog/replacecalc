#Copyright (c) 2012 Andrew Etches
#
#Permission is hereby granted, free of charge, to any person obtaining a copy 
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

use strict;
use vars qw($VERSION %IRSSI);

use Irssi;
use URI::Escape;
use LWP::UserAgent;
use JSON::PP;

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
        my $parseurl = $1;
        my $dp = -1;

        if($parseurl =~ /([^|]+) *\| *([0-9]+)/){
            $parseurl = $1;
            $dp = $2;
        }

        if($dp > 7){
            $dp = 7;
        }

        my $url = "http://www.google.com/ig/calculator?num=1&q=".uri_escape($parseurl);

        my $response = $agent->get($url)->content;
        $response =~ s/([a-z]+)\:/\"$1\"\:/g;

        $response =~ s/\\x26#215;/x/g;
        $response =~ s/\\x3csup\\x3e/ ^ /g;
        $response =~ s/\\x3c\/sup\\x3e//g;

        my $json = (new JSON::PP)->decode($response);
        my $error = $json->{error};
        my $result = $json->{rhs};

        $result =~ s/[^-0-9.,x ^]//g;

        # if we're dealing with a an exponent number the we need to handle it properly
        # otherwise, if we need to do some rounding then do that
        # otherwise there are no changes to be made
        if($result =~ /(-?[0-9.]+) x 10 \^ (-?[0-9]+)/){
            $result = sprintf "%.".$dp."f x 10 ^ %d", $1, $2;
        } elsif($dp != -1) {
            $result = sprintf "%.".$dp."f", $result;
        }

        $data =~ s/\@\{[^\}]+\}\@/$result/;

        if($error != ""){
            print "Sorry your query resulted in an error";
            next;
        }
    }

    $server->command("MSG $witem->{name} $data");
    Irssi::signal_stop();
}

Irssi::signal_add("send text", "replace")
