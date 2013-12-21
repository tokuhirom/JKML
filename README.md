# NAME

JKML::PP - It's new $module

# SYNOPSIS

    use JKML::PP;

# DESCRIPTION

JKML::PP is parser library for JKML. JKML is extended version of JSON.

JKML extends following features:

- Raw strings

    JKML allows raw strings. Such as following:

        r"hoge"
        r'hoge'
        r"""hoge"""
        r'''hoge'''

    Every raw string literals does not care about non terminater characters.

    It likes Python's.

- Comments

    JKML allows comments in the notation.

        {
            "foo": "bar", /*
                hogehoge
            */
            "baz": "boz", // single line comment
        }

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

## JSON::Tiny LICENSE

Copyright 2012-2013 David Oswald.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.
See http://www.perlfoundation.org/artistic\_license\_2\_0 for more information.


