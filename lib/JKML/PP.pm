package JKML::PP;
use 5.008005;
use strict;
use warnings;
use parent qw(Exporter);
use Encode ();
use MIME::Base64 ();

our @EXPORT = qw(decode_jkml);

our $VERSION = "0.01";

# JKML::PP is based on JSON::Tiny.
# JSON::Tiny was "Adapted from Mojo::JSON and Mojo::Util".

# Licensed under the Artistic 2.0 license.
# http://www.perlfoundation.org/artistic_license_2_0.

sub new {
  my $class = shift;
  bless {}, $class;
}

my $FALSE = bless \(my $false = 0), 'JKML::PP::_Bool';
my $TRUE  = bless \(my $true  = 1), 'JKML::PP::_Bool';

# Escaped special character map (with u2028 and u2029)
my %ESCAPE = (
  '"'     => '"',
  '\\'    => '\\',
  '/'     => '/',
  'b'     => "\x08",
  'f'     => "\x0c",
  'n'     => "\x0a",
  'r'     => "\x0d",
  't'     => "\x09",
  'u2028' => "\x{2028}",
  'u2029' => "\x{2029}"
);

my $WHITESPACE_RE = qr/[\x20\x09\x0a\x0d]/;
my $COMMENT_RE = qr!#[^\n]+(?:\n|\z)!;
my $IGNORABLE_RE = qr!(?:$WHITESPACE_RE|$COMMENT_RE)*!;

sub decode_jkml { JKML::PP->new->decode(shift) }


sub decode {
  my ($self, $bytes) = @_;

  # Missing input
  die 'Missing or empty input' unless $bytes;

  # Wide characters
  die 'Wide character in input'
    unless utf8::downgrade($bytes, 1);

  # Object or array
  my $res = eval {
    local $_ = $bytes;

    # Leading whitespace
    m/\G$IGNORABLE_RE/gc;

    # Array
    my $ref = _decode_value();

    # Leftover data
    unless (m/\G$IGNORABLE_RE\z/gc) {
      my $got = ref $ref ? lc(ref($ref)) : 'scalar';
      _exception("Unexpected data after $got");
    }

    $ref;
  };

  # Exception
  if (!$res && (my $e = $@)) {
    chomp $e;
    die $e;
  }

  return $res;
}

sub false {$FALSE}

sub true {$TRUE}

sub _decode_array {
  my @array;
  until (m/\G$IGNORABLE_RE\]/gc) {

    # Value
    push @array, _decode_value();

    # Separator
    my $found_separator = 0;
    if (m/\G$IGNORABLE_RE,/gc) {
        $found_separator++;
    }

    # End
    last if m/\G$IGNORABLE_RE\]/gc;

    redo if $found_separator;

    # Invalid character
    _exception('Expected comma or right square bracket while parsing array');
  }

  return \@array;
}

sub _decode_object {
  my %hash;
  until (m/\G$IGNORABLE_RE\}/gc) {
    # Key
    my $key = do {
      if (m/\G$IGNORABLE_RE([A-Za-z][a-zA-Z0-9_]*)/gc) {
        $1;
      } else {
        # Quote
        m/\G$IGNORABLE_RE"/gc
            or _exception('Expected string while parsing object');

        _decode_string();
      }
    };

    # Colon
    m/\G$IGNORABLE_RE=>/gc
      or _exception('Expected "=>" while parsing object');

    # Value
    $hash{$key} = _decode_value();

    # Separator
    my $found_separator = 0;
    $found_separator++ if m/\G$IGNORABLE_RE,/gc;

    # End
    last if m/\G$IGNORABLE_RE\}/gc;

    redo if $found_separator;

    # Invalid character
    _exception('Expected comma or right curly bracket while parsing object');
  }

  return \%hash;
}

sub _decode_string {
  my $pos = pos;
  # Extract string with escaped characters
  m!\G((?:(?:[^\x00-\x1f\\"]|\\(?:["\\/bfnrt]|u[0-9a-fA-F]{4})){0,32766})*)!gc; # segfault on 5.8.x in t/20-mojo-json.t #83
  my $str = $1;

  # Invalid character
  unless (m/\G"/gc) {
    _exception('Unexpected character or invalid escape while parsing string')
      if m/\G[\x00-\x1f\\]/;
    _exception('Unterminated string');
  }

  # Unescape popular characters
  if (index($str, '\\u') < 0) {
    $str =~ s!\\(["\\/bfnrt])!$ESCAPE{$1}!gs;
    return $str;
  }

  # Unescape everything else
  my $buffer = '';
  while ($str =~ m/\G([^\\]*)\\(?:([^u])|u(.{4}))/gc) {
    $buffer .= $1;

    # Popular character
    if ($2) { $buffer .= $ESCAPE{$2} }

    # Escaped
    else {
      my $ord = hex $3;

      # Surrogate pair
      if (($ord & 0xf800) == 0xd800) {

        # High surrogate
        ($ord & 0xfc00) == 0xd800
          or pos($_) = $pos + pos($str), _exception('Missing high-surrogate');

        # Low surrogate
        $str =~ m/\G\\u([Dd][C-Fc-f]..)/gc
          or pos($_) = $pos + pos($str), _exception('Missing low-surrogate');

        # Pair
        $ord = 0x10000 + ($ord - 0xd800) * 0x400 + (hex($1) - 0xdc00);
      }

      # Character
      $buffer .= pack 'U', $ord;
    }
  }

  # The rest
  return $buffer . substr $str, pos($str), length($str);
}

sub _decode_value {

  # Leading whitespace
  m/\G$IGNORABLE_RE/gc;

  # Raw string
  return $1 if m/\Graw\[(.*?)\]/gc;
  return $1 if m/\Graw\{(.*?)\}/gc;
  return $1 if m/\Graw\((.*?)\)/gc;
  return $1 if m/\Graw!(.*?)!/gc;
  return $1 if m/\Graw<(.*?)>/gc;
  return $1 if m/\Graw'(.*?)'/gc;
  return $1 if m/\Graw"(.*?)"/gc;

  # Base64 string
  if (m/\Gbase64\(([^']*)\)/gc) {
    return MIME::Base64::decode_base64($1);
  }

  # String
  return _decode_string() if m/\G"/gc;

  # Array
  return _decode_array() if m/\G\[/gc;

  # Object
  return _decode_object() if m/\G\{/gc;

  # Number
  return 0 + $1
    if m/\G([-]?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)/gc;

  # True
  return $TRUE if m/\Gtrue/gc;

  # False
  return $FALSE if m/\Gfalse/gc;

  # Null
  return undef if m/\Gnull/gc;  ## no critic (return)

  # Invalid character
  _exception('Expected string, array, object, number, boolean or null');
}

sub _exception {

  # Leading whitespace
  m/\G$IGNORABLE_RE/gc;

  # Context
  my $context = 'Malformed JKML: ' . shift;
  if (m/\G\z/gc) { $context .= ' before end of data' }
  else {
    my @lines = split /\n/, substr($_, 0, pos);
    $context .= ' at line ' . @lines . ', offset ' . length(pop @lines || '');
  }

  die "$context\n";
}

# Emulate boolean type
package JKML::PP::_Bool;
use overload '0+' => sub { ${$_[0]} }, '""' => sub { ${$_[0]} }, fallback => 1;

1;
__END__

=encoding utf-8

=head1 NAME

JKML::PP - Just K markup language in pure perl

=head1 SYNOPSIS

    use JKML::PP;
    decode_jkml(<<'...');
    {
        foo => raw(bar), # comment
        baz => 5,
    }
    ...

=head1 DESCRIPTION

JKML::PP is parser library for JKML. JKML is yet another markup language.

=head2 What's difference between JSON?

JKML extends following features:

=over 4

=item Raw strings

=item Comments

=back

=head1 JKML and encoding

You MUST use UTF-8 for every JKML data.

=head1 JKML Grammar

=over 4

=item Raw strings

JKML allows raw strings. Such as following:

    raw_string =
          'raw(' .*? ')'
        | 'raw"' .*? '"'
        | "raw'" .*? "'"
        | "raw[" .*? "]"
        | "raw{" .*? "}"
        | "raw<" .*? ">"

Every raw string literals does not care about non terminater characters.

    raw[hoge]
    raw(hoge)
    raw{hoge}
    raw!hoge!

=item Base64 notation

    base64 = "base64(" base85char ")"
    base64char = [
        ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
    ]

Example:

    base64(...)

=item Comments

Perl5 style comemnt is allowed.

    # comment

=item String

String literal is compatible with JSON. See JSON RFC.

    "Hello, \u3344"

=item Number

Number literal is compatible with JSON. See JSON RFC.

    3
    3.14
    3e14

=item Map

Map literal's grammar is:

    pair = string "=>" value
    map = "{" "}"
        | "{" pair ( "," pair )* ","?  "}"

You can omit quotes for keys, if you don't want to type it.

You can use trailing comma unlike JS.

Examples:

    {
        a => 3,
        "b" => 4,
    }

=item Array

    array = "[" "]"
          | "[" value ( "," value )* ","? "]"

Examples:

    [1,2,3]
    [1,2,3,]

=item Value

    value = map | array | string | raw_string | number

=item Boolean

    bool = "true" | "false"

=item NULL

    null = "null"

Will decode to C<undef>.

=back

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=head1 LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head2 JSON::Tiny LICENSE

This library uses JSON::Tiny's code. JSON::Tiny's license term is following:

Copyright 2012-2013 David Oswald.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.
See http://www.perlfoundation.org/artistic_license_2_0 for more information.


=cut

