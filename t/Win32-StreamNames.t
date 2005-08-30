# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-StreamNames.t'

#########################

use Test::More tests => 22;
use Win32API::File qw (:Func);
use Cwd;

# Check module is there (1)
BEGIN { use_ok('Win32::StreamNames') };

#########################
# Create the file and streams
# Cannot distribute streams with files - they do not survive the zip process
sub create_file ($)
{
   my ($file) = @_;
   open (FILE, '>', $file) or die "Unable to open $file: $!";
   print FILE "This is $file\n";
   close FILE;

}  # create_file

#########################

# Sanity check (2)
is($^O, 'MSWin32', 'OS is Windows');

# Construct the test directory (used later) & file name
my $dir = $0;
$dir =~ s/([\/\\]).*$/$1/;


# NTFS ??
my $sRootPath = (split /[\\\/]/, getcwd())[0].'\\';
my $osVolName = ' ' x 260;
my $osFsType  = ' ' x 260;

GetVolumeInformation( $sRootPath, $osVolName, 260, [], [], [], $osFsType, 260 );
is($osFsType, "NTFS") or diag "These tests will only run on NTFS, not $osFsType";

# Prepare for testing
$^E = 0;

my $file = $dir.'test.txt';

create_file ($file);
create_file ($file.':stream1');
create_file ($file.':stream2');
create_file ($file.':stream3');
create_file ($file.':stream4');

# Is the test file ok? (3 & 4)
ok(-f $file, "$file exists ok");
ok(-r $file, "$file exists ok");

# Open the test file (5)
@list = StreamNames($file);
is(0+$^E, 0, 'os error ok') or diag ("$^E: Value of \$file is: $file<<\n");

# Stream names (6..9)
for $stream (@list)
{
   ok(open (HANDLE, $file.$stream), "Stream $file$stream ok") or diag ("$file$stream: $!");
   close HANDLE;
}

# 4 streams in this file (10)
is(@list, 4, 'Number of streams') or diag ("@list");
unlink $file;

# Directory? (11, 12)

@list = StreamNames('.');
ok(!@list, 'Directory list') or diag ("@list");
is (0+$^E, 5, 'Attempt to open a directory EPERM');

# No such file (13, 14)#
@list = StreamNames('gash.zzz');
ok (!@list, 'Empty list on ENOENT') or diag ("@list");
is (0+$^E, 2, 'ENOENT');

# Long file name (15, 16)
$file = $dir.'ThisIsAveryLongFileNameWhichGoesOnAndOn';
create_file ($file);
create_file ($file.':AndThisIsAlsoAVeryLongStreamNameAsWell');

@list = StreamNames($file);
is ("@list", ':AndThisIsAlsoAVeryLongStreamNameAsWell:$DATA') or diag ("@list");
is (0+$^E, 0, 'Long one');
unlink $file;

# Embeded spaces (17, 18, 19)
$file = $dir.'Embedded space in filename';
create_file ($file);
create_file ($file.':Embedded space in stream name');

@list = StreamNames($file);
is (@list, 1, 'Embedded space in filename, list') or diag ("File: $file, List: @list\n");
is (0+$^E, 0, 'Embedded space in filename, oserr') or diag ("@list\n$file");
is ("@list", ':Embedded space in stream name:$DATA', 'Embedded space in filename, list');
unlink $file;

# No streams in file (20, 21);
$file = $dir.'NoStreams.txt';
create_file ($file);

@list = StreamNames($file);
ok (!@list, 'Empty list on no streams') or diag ("@list");
is (0+$^E, 0, 'No streams, oserr') or diag ("@list\n$file");
unlink $file;


