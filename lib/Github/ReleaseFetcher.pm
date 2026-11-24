package Github::ReleaseFetcher;

use 5.014;
use strict;
use warnings FATAL => 'all';
no autovivification;

# ABSTRACT: Fetch either the latest or a particular named version of a file in a release from github

use Carp::Always;
use HTTP::Tiny();
use HTML::TreeBuilder::Select();
use File::Basename qw{basename};

=head1 DESCRIPTION

Scrapes the github release page and reads the hrefs from the 'Assets' section.
This is because there isn't a publicly accessable machine-readable version of this listing.
As such you need this instead of freebasing JSON directly into your veins.

Relies both on the 'latest' redirect for releases on github, and the expanded_assets page.
If either of these stop working, so will this module.

=head1 SYNOPSIS

    my @files = Github::ReleaseFetcher::fetch(".", "SeleniumHQ", "selenium", { search => qr/\.jar$/ } );

=head1 SUBROUTINES

=head2 fetch(STRING $outdir, STRING $owner, STRING $project, [HASHREF $options])

Fetches the file(s) from the latest release within $owner's $project.

The optional hash reference $options can hold these keys:

=over

=item search: a regex that the asset paths must match.

=item rename: the name to give the output file.

=item version: a release to fetch instead of the latest one.

=item ua: a configured HTTP::Tiny user agent to do the fetch.

=back

In the event of a rename (which will result in multiple files being named the same thing), the last lexically sorted result will hold precedence.

Returns list of files written, or in the case that outdir is a false value, the URIs where said assets reside.

=cut

our $BASE_URI = "http://github.com";

sub fetch {
    my ( $outdir, $owner, $project, $options ) = @_;
    $options //= {};
    my ( $search, $rename, $version, $ua ) = @{$options}{qw{search rename version ua}};

    die "Must pass outdir that exists" if $outdir && !-d $outdir;
    die "Must pass owner"   unless $owner;
    die "Must pass project" unless $project;

    $outdir //= "";

    $version //= 'latest';
    my $index = "$BASE_URI/$owner/$project/releases/$version";

    $ua //= HTTP::Tiny->new();

    # Figure out *what* the latest version number is.
    if ( $version eq 'latest' ) {
        my $latest = $ua->get($index);
        die "$latest->{reason} :\n$latest->{content}\n" unless $latest->{success};

        #Snag the url we were redirected to, as this is the actual version
        $version = basename( $latest->{url} );
    }
    $index = "$BASE_URI/$owner/$project/releases/expanded_assets/$version";
    my $res = $ua->get($index);
    die "$res->{reason} :\n$res->{content}\n" unless $res->{success};

    my $parsed = HTML::TreeBuilder::Select->new_from_content( $res->{content} );
    my @links;
    foreach my $anchor ( $parsed->select('a') ) {
        my @found = $anchor->extract_links();
        push @links, @found;
    }
    my @matches =
      map { $_->[0][0] }
      grep { ref $_ eq "ARRAY" && ref $_->[0] eq "ARRAY"; } @links;
    @matches = grep { $_ =~ $search } @matches if $search;

    my %names;
    foreach my $subj (@matches) {
        my $name = $rename // basename($subj);
        $names{"$BASE_URI/$subj"} = "$outdir/$name";
    }

    foreach my $to_write ( reverse sort keys %names ) {
        $ua->mirror( $to_write, $names{$to_write} ) if $outdir;
        last                                        if $rename;
    }

    return keys(%names) unless $outdir;

    my @written = values(%names);
    return pop(@written) if $rename;
    return @written;
}

1;
