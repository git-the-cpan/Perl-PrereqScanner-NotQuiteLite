package Perl::PrereqScanner::NotQuiteLite::Context;

use strict;
use warnings;
use CPAN::Meta::Requirements;
use Perl::PrereqScanner::NotQuiteLite::Util;

sub new {
  my ($class, %args) = @_;

  my %context = (
    requires => CPAN::Meta::Requirements->new,
  );

  if ($args{suggests}) {
    $context{suggests} = CPAN::Meta::Requirements->new;
  }
  for my $type (qw/use no method keyword/) {
    if (exists $args{_}{$type}) {
      for my $key (keys %{$args{_}{$type}}) {
        $context{$type}{$key} = [@{$args{_}{$type}{$key}}];
      }
    }
  }

  bless \%context, $class;
}

sub register_keyword {
  my ($self, $keyword, $parser_info) = @_;
  $self->{keyword}{$keyword} = $parser_info;
}

sub remove_keyword {
  my ($self, $keyword) = @_;
  delete $self->{keyword}{$keyword};
  delete $self->{keyword} if !%{$self->{keyword}};
}

sub register_method {
  my ($self, $method, $parser_info) = @_;
  $self->{method}{$method} = $parser_info;
}

sub requires { shift->{requires} }

sub suggests {
  my $self = shift;
  my $suggests = $self->{suggests} or return;

  # no need to suggest what are listed as requires
  if (my $requires = $self->{requires}) {
    my $hash = $suggests->as_string_hash;
    for my $module (keys %$hash) {
      if (defined $requires->requirements_for_module($module) and
          $requires->accepts_module($module, $hash->{$module})
      ) {
        $suggests->clear_requirement($module);
      }
    }
  }
  $suggests;
}

sub add {
  my ($self, $module, $version) = @_;
  return unless is_module_name($module);

  my $CMR = $self->_object or return;
  $version = 0 unless defined $version;
  $CMR->add_minimum($module, "$version");
}

sub has_added {
  my ($self, $module) = @_;
  return unless is_module_name($module);

  my $CMR = $self->_object or return;
  defined $CMR->requirements_for_module($module) ? 1 : 0;
}

sub _object {
  my $self = shift;
  my $key = $self->is_in_eval ? 'suggests' : 'requires';
  $self->{$key} or return;
}

sub skips_eval {
  my $self = shift;
  return $self->{suggests} ? 0 : 1;
}

sub is_in_eval {
  my $self = shift;

  exists $self->{eval} ? 1 : 0;
}

sub enter_eval {
  my ($self, $depth) = @_;
  push @{$self->{eval} ||= []}, $depth;
}

sub exit_eval_if_match {
  my ($self, $depth) = @_;
  return unless exists $self->{eval};
  if ($self->{eval}[-1] == $depth) {
    pop @{$self->{eval}};
    delete $self->{eval} if !@{$self->{eval}};
  }
}

sub has_callbacks {
  my ($self, $type) = @_;
  exists $self->{$type};
}

sub has_callback_for {
  my ($self, $type, $name) = @_;
  exists $self->{$type}{$name};
}

sub run_callback_for {
  my ($self, $type, $name, @args) = @_;
  return unless $self->_object;
  my ($parser, $method, @cb_args) = @{$self->{$type}{$name}};
  $parser->$method($self, @cb_args, @args);
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::NotQuiteLite::Context

=head1 DESCRIPTION

This is typically used to keep callbacks, an eval state, and
found prerequisites for a processing file.

=head1 METHODS

=head2 add

  $c->add($module);
  $c->add($module => $minimum_version);

adds a module with/without a minimum version as a requirement
or a suggestion, depending on the eval state. You can add a module
with different versions as many times as you wish. The actual
minimum version for the module is calculated inside
(by L<CPAN::Meta::Requirements>).

=head2 enter_eval, exit_eval_if_match, is_in_eval, skips_eval

  $c->enter_eval($tokens->block_depth);
  if (!$c->skips_eval or !$c->is_in_eval) {
    ... # do something
  }
  $c->exit_eval_if_match($tokens->block_depth + 1);

If you find a token for C<eval> or its equivalents,
call C<enter_eval> to tell the context object from which block the
eval has started. (You can pass a negative value when a string
C<eval> is found). You can use C<exit_eval_if_match> to
end C<eval> when you get out of the block.

=head2 register_keyword, remove_keyword, register_method

  $c->register_keyword(
    'func_name',
    [$parser_class, 'parser_for_the_func', $used_module],
  );
  $c->remove_keyword('func_name');

  $c->register_method(
    'method_name',
    [$parser_class, 'parser_for_the_method', $used_module],
  );

If you find a module that can export a loader function is actually
C<use>d (such as L<Moose> that can export an C<extends> function
that will load a module internally), you might also register the
loader function as a custom keyword dynamically so that the scanner
can also run a callback for the function to parse its argument
tokens.

You can also remove the keyword when you find the module is C<no>ed
(and when the module supports C<unimport>).

You can also register a method callback on the fly (but you can't
remove it).

If you always want to check some functions/methods when you load a
plugin, just register them using a C<register> method in the plugin.

=head2 requires

returns a CPAN::Meta::Requirements object for requirements.

=head2 suggests

returns a CPAN::Meta::Requirements object for suggestions
(requirements in C<eval>s), or undef when it is not expected to
parse tokens in C<eval>.

=head1 METHODS MOSTLY FOR INTERNAL USE

=head2 new

creates an instance. You usually don't need to call this because
it's automatically created in the scanner.

=head2 has_callbacks, has_callback_for, run_callback_for

  next unless $c->has_callbacks('use');
  next unless $c->has_callbacks_for('use', 'base');
  $c->run_callbacks_for('use', 'base', $tokens);

C<has_callbacks> returns true if a callback for C<use>, C<no>,
C<keyword>, or C<method> is registered. C<has_callbacks_for>
returns true if a callback for the module/keyword/method is
registered. C<run_callbacks_for> is to run the callback.

=head2 has_added

returns true if a module has already been added as a requirement
or a suggestion. Only useful for the ::UniversalVersion plugin.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
