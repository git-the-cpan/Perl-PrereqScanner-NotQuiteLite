package Perl::PrereqScanner::NotQuiteLite::Util;

use strict;
use warnings;
use Exporter 5.57 qw/import/;

our @EXPORT = qw/
  is_module_name
  is_version
/;

sub is_module_name {
  my $name = shift or return;
  return 1 if $name =~ /^[A-Za-z_][A-Za-z0-9_]*(?:(?:::|')[A-Za-z0-9_]+)*$/;
  return;
}

sub is_version {
  my $version = shift;
  return unless defined $version;
  return 1 if $version =~ /\A
    (
      [0-9]+(?:\.[0-9]+)?
      |
      v[0-9]+(?:\.[0-9]+)*
      |
      [0-9]+(?:\.[0-9]+){2,}
    ) (?:_[0-9]+)?
  \z/x;
  return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::NotQuiteLite::Util

=head1 DESCRIPTION

This provides a few utility functions for internal use.

=head1 FUNCTIONS

=head2 is_module_name

takes a string and returns true if it looks like a module.

=head2 is_version

takes a string and returns true if it looks like a version.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
