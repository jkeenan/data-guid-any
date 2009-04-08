# Copyright (c) 2009 by David Golden. All rights reserved.
# Licensed under Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License was distributed with this file or you may obtain a
# copy of the License from http://www.apache.org/licenses/LICENSE-2.0

package Data::GUID::Any;
use 5.006;
use strict;
use warnings;
use Config;
use File::Spec;
use base 'Exporter';

our $VERSION = '0.001';
$VERSION = eval $VERSION; ## no critic

our @EXPORT_OK = qw/ guid_as_string /;

our $Using;

#--------------------------------------------------------------------------#

my $hex = "A-Z0-9";

sub _looks_like_guid {
  my $guid = shift;
  return $guid =~ /[$hex]{8}-[$hex]{4}-[$hex]{4}-[$hex]{4}-[$hex]{12}/;
}

#--------------------------------------------------------------------------#

my %binaries = (
  uuid => {
    cmd => 'uuid',
    args => '-v1',
  },
);

sub _check_binaries {
  for my $bin ( keys %binaries ) {
    my ($cmd, $args) = @{$binaries{$bin}}{qw/cmd args/};
    my ($path) =  grep { -x }
                map { File::Spec->catfile( $_, $cmd ) } File::Spec->path;
    next unless $path;
    my $sub = sub { chomp( my $guid = qx/$path $args/ ); return uc $guid };
    return ($bin, $sub) if _looks_like_guid( $sub->() );
  }
}

#--------------------------------------------------------------------------#

sub _preferred_modules { return qw/Data::GUID Data::UUID Win32/ }

my %modules = (
  'Data::GUID' => sub { return Data::GUID->new->as_string },
  'Data::UUID' => sub { return Data::UUID->new->create_str },
  'Win32' => sub { my $guid = Win32::GuidGen(); return substr($guid,1,-1) },
);

sub _check_modules {
  for my $mod ( _preferred_modules() ) {
    next unless eval "require $mod; 1";
    my $sub = $modules{$mod};
    return ($mod, $sub) if _looks_like_guid( $sub->() );
  }
}

#--------------------------------------------------------------------------#

my ($which_bin, $bin_sub) = _check_binaries();
my ($which_mod, $mod_sub) = _check_modules();

die "Couldn't find a GUID module or binary" unless $bin_sub || $mod_sub;

{
  no warnings;
  if ( $mod_sub ) {
    *guid_as_string = $mod_sub;
    $Using = $which_mod
  }
  else {
    *guid_as_string = $bin_sub;
    $Using = $which_bin
  }
}

1;

__END__

=begin wikidoc

= NAME

Data::GUID::Any - Generic interface for GUID creation

= VERSION

This documentation describes version %%VERSION%%.

= SYNOPSIS

    use Data::GUID::Any 'guid_as_string';

    my $guid = guid_as_string();

= DESCRIPTION

This module is a generic wrapper

= USAGE

== guid_as_string()

    my $guid = guid_as_string();

Returns a guid in string format (upper-case hex characters):

  FA2D5B34-23DB-11DE-B548-0018F34EC37C



= BUGS

Please report any bugs or feature requests using the CPAN Request Tracker
web interface at [http://rt.cpan.org/Dist/Display.html?Queue=Data-GUID-Any]

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

= SEE ALSO


= AUTHOR

David A. Golden (DAGOLDEN)

= COPYRIGHT AND LICENSE

Copyright (c) 2009 by David A. Golden. All rights reserved.

Licensed under Apache License, Version 2.0 (the "License").
You may not use this file except in compliance with the License.
A copy of the License was distributed with this file or you may obtain a
copy of the License from http://www.apache.org/licenses/LICENSE-2.0

Files produced as output though the use of this software, shall not be
considered Derivative Works, but shall be considered the original work of the
Licensor.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=end wikidoc

=cut

