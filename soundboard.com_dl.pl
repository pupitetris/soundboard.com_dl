#!/usr/bin/perl

#    Copyright (C) 2025, Arturo Espinosa Aldama <pupitetris@yahoo.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

use strict;

use File::MimeInfo::Magic qw(extensions mimetype); # libfile-mimeinfo-perl
use File::Path qw(make_path);
use HTML::Entities; # libhtml-parser-perl
use IO::Scalar;
use JSON; # libjson-perl
use LWP::Simple; # liblwp-protocol-https-perl
use MIME::Base64;
use URI; # liburi-perl

$LWP::Simple::ua->agent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36');

die 'Specify soundboard.com soundboard URL as first argument' if !defined($ARGV[0]);

$::URL = URI->new($ARGV[0]);
die "'$::URL' is not a web URL" if ref($::URL) ne 'URI::http' && ref($::URL) ne 'URI::https';
die "'$::URL' is missing the host name" if $::URL->host eq '';

$::ROOT = $::URL->scheme . '://' . $::URL->host . ':' . $::URL->port . '/';

sub track {
    my $fd = shift;
    my $id = shift;
    my %track = ('id' => $id);
    my $divs = 1;

    while (my $l = <$fd>) {
	$divs++ if $l =~ /<div[\s>]/;
	$divs-- if $l =~ /<\/div>/;
	last if $divs == 0;
	
	if ($l =~ /[" ]item-title[" ]/) {
	    $l = <$fd>;
	    $l =~ /<span(\s[^>]*|)>([^<]+)/;
	    $track{'title'} = decode_entities($2);
	}
    }

    return \%track;
}

sub tracks {
    my $fd = shift;
    my @tracks = ();

    while (my $l = <$fd>) {
	if ($l =~ /data-src="([^"]+)"/) {
	    push @tracks, track($fd, $1);
	}
    }

    return \@tracks;
}

sub page {
    my $fd = shift;
    my $meta = shift;
    
    while (my $l = <$fd>) {
	if ($l =~ /[" ]item-media-content[" ]/) {
	    $l =~ /boardicon\/([^.]+)(\.[^)]+)/;
	    if ($1) {
		$meta->{'id'} = $1;
		my $fname = "boardicon$2";
		my $url = $::ROOT . "boardicon/$1$2";
		getstore($url, $fname) if ! -e $fname;
	    }
	}
	if ($l =~ /<h1(\s[^>]*|)>([^<]+)/) {
	    $meta->{'title'} = $2;
	}
	if ($l =~ /[" ]item-desc[" ]/) {
	    $l =~ /<p(\s[^>]*|)>([^<]+)/;
	    $meta->{'desc'} = $2;
	}
	if ($l =~ /[" ]item-author[" ]/) {
	    $l =~ /href="\/user\/([^"]+)/;
	    $meta->{'author_id'} = $1;
	    $l =~ /<a(\s[^>]*|)>([^<]+)/;
	    $meta->{'author'} = $2;
	}
	if ($l =~ /id="tracks"/) {
	    $meta->{'tracks'} = tracks($fd);
	}
    }
}

if (! -e 'index.html') {
    my $code = getstore($::URL, 'index.html');
    if ($code != 200) {
	die "Couldn't retrieve $::URL";
    }
}

my %meta = ();
open(my $fd, '<index.html') || die $!;
while (my $l = <$fd>) {
    page($fd, \%meta) if $l =~ /<div\s+class="page-content">/;
}
close($fd);

my $json = JSON->new->utf8->canonical->pretty->space_before(0);

open(my $jfd, '>metadata.json') || die $!;
print $jfd $json->encode(\%meta);
close($jfd);

mkdir 'tracks' || die $! if ! -e 'tracks';
mkdir 'tracks/json' || die $! if ! -e 'tracks/json';

my $idx = 0;
my $tracks = $meta{'tracks'};
my $numtracks = $#$tracks + 1;
my $idxlen = length($numtracks);
foreach my $track (@$tracks) {
    $idx++;
    my $song = sprintf("%0${idxlen}d", $idx) . '-' . $track->{'id'} . '-' . $track->{'title'};
    my $json_fname = "tracks/json/$song.json";
    print "$idx/$numtracks $song\n";

    my $url = $::ROOT . 'track/' . $track->{'id'};
    getstore($url, $json_fname) if ! -e $json_fname;

    open(my $jfd, $json_fname) || die $!;
    my $json_str = do { local $/; <$jfd> };
    close($jfd);

    my $track_obj = $json->decode($json_str);
    my $track_data = decode_base64($track_obj->[0]->{'data'});
    my $scalar_io = IO::Scalar->new(\$track_data);
    my $mime_type = mimetype($scalar_io);
    my $ext = extensions($mime_type);
    $ext = (defined $ext)? lc($ext =~ s/^\.//r) : "dat";

    open(my $songfd, '>:raw', "tracks/$song.$ext") || die $!;
    print $songfd $track_data;
    close($songfd);
}
