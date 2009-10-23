#!/usr/bin/perl

use strict;
use warnings;

use HTML::TreeBuilder;
use Data::Dumper;

=head1 NAME

delicious_to_base_format.pl - Convert exported Delicious bookmarks to base markup

=head1 DESCRIPTION

This script converts an exported Delicious Bookmarks file into a markup
used at http://st.mahesha.com/bs/. This markup is very similar to
the Bookmarks file used in browsers.

=head1 USAGE

The script takes the name of bookmarks file exported from Delicious Bookmarks
site - https://secure.delicious.com/settings/bookmarks/export. Bookmarks are
exported along with tags and notes. The converted markup is printed to the
STDOUT. It can then be redirected to a file if required.

    % delicious_to_base_format.pl delicious-20090409.html > mybm.html

In the intended use, this markup goes directly in the C<div> with C<id>
C<bookmarks> in http://st.mahesha.com/bs/index.html.

=cut

#
# Bookmarks storage
#
my $bms = {};

#
#
#
my $bm_tree = HTML::TreeBuilder->new_from_content(<>);

#
# Get the bookmarks folder list
#
my $bm_db = get_first_tag_ref ('dl', $bm_tree);

handle_bm_item_list($bm_db, $bms);
present_bm_items($bms);

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
      $ret_ref = get_first_tag_ref ($tag, $content_item)
        if (ref($content_item) eq "HTML::Element");
      last if (defined $ret_ref);
    }
  }

  return $ret_ref;
}

sub handle_bm_item_list {
  my ($item_list, $bms) = @_;

  foreach my $bm_item (@{$item_list}) {
    next unless ((ref($bm_item) eq "HTML::Element")
                  && ($bm_item->{'_tag'} eq 'dt'));

    #
    # Get each item in the folder
    #
    $bm_item->{'_content'}[0]->{'href'} =~ s/&/&amp;/g;
    $bm_item->{'_content'}[0]->{'_content'}[0] =~ s/&/&amp;/g;
    my @tags = split ',', $bm_item->{'_content'}[0]->{'tags'};
    foreach my $tag (@tags) {
      $tag = lc ($tag);
      $bms->{$tag} = [] unless exists $bms->{$tag};

      my $bm =  "      <dd><a href=\"" . $bm_item->{'_content'}[0]->{'href'} . "\"\n" .
                "             title=\"" . $bm_item->{'_content'}[0]->{'href'} . "\"\n" .
                "             target=\"_blank\">" .
                $bm_item->{'_content'}[0]->{'_content'}[0] . "</a></dd>\n";
      push (@{$bms->{$tag}}, $bm);
    }
  }
}

sub present_bm_items {
  my ($bms) = @_;

  foreach my $bm_grp (sort keys %$bms) {
    print "    <dl> <dt>$bm_grp</dt>\n";
    foreach my $bm_item (@{$bms->{$bm_grp}}) {
      print $bm_item;
    }
    print "    </dl>\n";
  }
}

=head1 AUTHOR

Mahesh Asolkar <mahesh@mahesha.com>

=cut
