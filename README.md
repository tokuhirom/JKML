# NAME

JKML::PP - Just K markup language in pure perl

# SYNOPSIS

    use JKML::PP;
    decode_jkml(<<'...');
    {
        foo => raw(bar), # comment
        baz => 5,
    }
    ...

# DESCRIPTION

JKML::PP is parser library for JKML. JKML is yet another markup language.

## What's difference between JSON?

JKML extends following features:

- Raw strings
- Comments

# JKML and encoding

You MUST use UTF-8 for every JKML data.

# JKML Grammar

- Raw strings

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

- Base64 notation

        base64 = "base64(" base85char ")"
        base64char = [
            ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
        ]

    Example:

        base64(...)

- Comments

    Perl5 style comemnt is allowed.

        # comment

- String

    String literal is compatible with JSON. See JSON RFC.

        "Hello, \u3344"

- Number

    Number literal is compatible with JSON. See JSON RFC.

        3
        3.14
        3e14

- Map

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

- Array

        array = "[" "]"
              | "[" value ( "," value )* ","? "]"

    Examples:

        [1,2,3]
        [1,2,3,]

- heredoc

    Ruby style heredoc.

        <<-TOC
        hoghoge
        TOC

- Value

        value = map | array | string | raw_string | number
- Boolean

        bool = "true" | "false"
- NULL

        null = "null"

    Will decode to `undef`.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

## JSON::Tiny LICENSE

This library uses JSON::Tiny's code. JSON::Tiny's license term is following:

Copyright 2012-2013 David Oswald.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.
See http://www.perlfoundation.org/artistic\_license\_2\_0 for more information.


