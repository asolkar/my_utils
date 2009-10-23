#!/usr/bin/perl

use strict;
use warnings;

use HTML::TreeBuilder;
use Data::Dumper;

=head1 NAME

google_bookmarks_to_base_format.pl - Convert exported Google Bookmarks to base markup

=head1 DESCRIPTION

This script converts an exported Google Bookmarks file into a markup
used at http://st.mahesha.com/bs/. This markup is very similar to
the Bookmarks file used in browsers.

=head1 USAGE

The script takes the name of bookmarks file exported from Google Bookmarks site - http://www.google.com/bookmarks/. The converted markup is printed to the STDOUT. It can then be redirected to a file if required.

    % google_bookmarks_to_base_format.pl GoogleBookmarks.html > mybm.html

In the intended use, this markup goes directly in the C<div> with C<id> C<bookmarks> in http://st.mahesha.com/bs/index.html.

=cut

my $bm_tree = HTML::TreeBuilder->new_from_content(<>);

#
# Get the bookmarks folder list
#
my $bm_db = get_first_tag_ref ('dl', $bm_tree);

handle_bm_database($bm_db);

# --------------------
# Subroutines
# --------------------
sub get_first_tag_ref {
  my ($tag, $tree) = @_;

  my $ret_ref;

  if ((exists $tree->{'_tag'}) && ($tree->{'_tag'} eq $tag)) {
    $ret_ref = $tree->{'_content'};
  } else {
    foreach my $content_item (@{$tree->{'_content'}}) {
      $ret_ref = get_first_tag_ref ($tag, $content_item) if (ref($content_item) eq "HTML::Element");
      last if (defined $ret_ref);
    }
  }

  return $ret_ref;
}

sub handle_bm_database {
  my ($folder_list) = @_;

  foreach my $bm_folder (@{$folder_list}) {
    next unless ((ref($bm_folder) eq "HTML::Element")
                  && ($bm_folder->{'_tag'} eq 'dt'));

    #
    # Get the name of the folder
    #
    my $folder_name_tag = get_first_tag_ref ('h3', $bm_folder);
    print "    <dl> <dt>" . ${$folder_name_tag}[0] . "</dt>\n";

    #
    # Get the contents of the folder
    #
    my $folder_items_tag = get_first_tag_ref ('dl', $bm_folder);
    handle_bm_item_list($folder_items_tag);
    print "    </dl>\n";
  }
}

sub handle_bm_item_list {
  my ($item_list) = @_;

  foreach my $bm_item (@{$item_list}) {
    next unless ((ref($bm_item) eq "HTML::Element")
                  && ($bm_item->{'_tag'} eq 'dt'));

    #
    # Get each item in the folder
    #
    $bm_item->{'_content'}[0]->{'href'} =~ s/&/&amp;/g;
    $bm_item->{'_content'}[0]->{'_content'}[0] =~ s/&/&amp;/g;
    print "      <dd><a href=\"" . $bm_item->{'_content'}[0]->{'href'} . "\"\n" .
          "             title=\"" . $bm_item->{'_content'}[0]->{'href'} . "\"\n" .
          "             target=\"_blank\">" .
          $bm_item->{'_content'}[0]->{'_content'}[0] . "</a></dd>\n"
  }
}

=head1 AUTHOR

Mahesh Asolkar <mahesh@mahesha.com>

=cut
