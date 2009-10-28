#!/depot/perl-5.8.3/bin/perl

use strict;
use warnings;
use Getopt::Long;

=head1 NAME

p4-diff.pl - Easy access to Perforce diff


=head1 SYNOPSIS

    p4-diff.pl --help

=pod

    p4-diff.pl [--ver=<revision number>] file [file2...]

=pod

    p4-diff.pl --all

=head1 USAGE

=over 2

=item *

Get help on usage

    % p4-diff.pl --help

=item *

Difference between specified file(s) in the client versus
a version of that file in depot

    % p4-diff.pl [--ver=<revision number>] file [file2...]

If a version is not specified, the head version is used.
C<--ver> can be specified with multiple files, but often does
not make sense.

=item *

Difference between all opened files in a client versus their
head version in depot

    % p4-diff.pl --all

In this case, C<--ver> can be specified, but often does not
make sense. Very useful in evaluating changes just before
checking in a change list.

=back

=head1 DIFF TOOL

=over 2

=item *

By default, vim is used as the DIFF tool

    @::diff = ("myvim", '-R', '-d');

It can be changed by modifying the above line in the initial
part of the script.

If the default is used, p4-diff.pl will open vim:

=over 4

=item *

In diff mode (-d)

=item *

In readonly mode (-R): So if a file is already open in another
session, there are no warnings. Although, if you need to edit
the file, you must use C<:w!> to write it back to the disk.

=back

=head1 OUTPUT

=item *

p4-diff.pl displays output like the following when starting
the diff tool.

    Diff [/some/path/Makefile]:
    Current (Ver 2+) <-> Ver 2 [/tmp/1224013087_p4-diff_2_Makefile]
    2 files to edit

Version 'n+' means that version 'n' of a file is checked out.

=back

=head1 FILES

p4-diff.pl will create temporary files in C</tmp>. The filenames are
derived from the name of the input file, perforce revision number of
the input file and the current time (to uniquify). An example of such
file is:

    /tmp/1224013087_p4-diff_2_Makefile

=head1 SEE ALSO

L<GetOpt::Long>

=head1 AUTHOR

2008 Mahesh Asolkar <maheshak@synopsys.com> 2008. This software is a property
of Synopsys, Inc.

=cut

#
# Diff utility
#   * Opens Vim
#     - In diff mode (-d)
#     - In readonly mode (-R): So if a file is already open in another
#       session, there are no warnings. Although, if you need to edit
#       the file, you must use ':w!' to write it back to the disk.
#
@::diff = ("myvim", '-R', '-d');

my $version = '';
my $all = 0;
my $help = 0;

#
# Get options and arguments
#
my $correct_usage = GetOptions ('help'    => \$help,
                                'ver=s'   => \$version,
                                'all'     => \$all,
                                'opened'  => \$all);

if ($help) {
  system ('perldoc', $0);
  exit (0);
}

my @files_to_diff = ($all)
                    ? `p4 where \`p4 opened | cut -f1 -d#\` | cut -f3 -d' '`
                    : @ARGV;

foreach my $file (@files_to_diff) {
  chomp $file;
  diff_file ($file, $version);
}

# ---------------------------------------
# Subroutines
# ---------------------------------------
sub diff_file {
  my $file = shift;
  my $version = shift;

  #
  # Make sure the file exists
  #
  warn "ERROR: Could not find file \'$file\'" if (! -e $file);

  #
  # Get file stats
  #
  my %filestats = get_file_stat ($file);

  #
  # Get the desired version in a temp tile
  #
  $version = $filestats{'headRev'} if ($version eq '');

  my $temp_file = temp_file_name ($file, $version);

  my $ver_access = join (' ',
                      'git',
                      '--no-pager',
                      'show',
                      $version.":".$file,
                      '>', $temp_file);

  print "\nEXEC: $ver_access\n";

  system ($ver_access);

  print "Diff [$file]:\n  Current <-> Ver $version [$temp_file]\n";

  #
  # Open diff diff
  #
  my @diff_exec = (@::diff,
                   $file,
                   $temp_file);

  system (@diff_exec);
}

sub get_file_stat {
  my $file = shift;
  my @ret = ();

  open (CMD, "git log $file |");  # Pipe at the end of the command means that I am
                                   # reading from the command. If it were at the beginning,
                                   # I could write in to the command
  while (<CMD>) {
    return @ret if (/^\s*$/);
    if (/^commit (.*)/) {
      push (@ret, 'headRev', $1);
    } elsif (/(\S+?):\s?(.*)/) {
      push (@ret, $1, $2);
    }
    print @ret;
  }
}

sub temp_file_name {
  my $file = shift;
  my $version = shift;

  my $name = "/tmp/" . time . "_" . int(rand(10000)) . "_git-diff_${version}_";

  my @path = split ('/', $file);
  $name .= $path[$#path];

  return $name;
}
