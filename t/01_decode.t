use strict;
use warnings;
use utf8;
use Test::More;
use JKML::PP;

is_deeply(decode_jkml(<<'...'), {});
{
}
...
is_deeply(decode_jkml(<<'...'), ['hogehoge']);
[r"hogehoge"]
...
is_deeply(decode_jkml(<<'...'), ['hogehoge', "h\\uh"]);
[
    r"hogehoge",
    r'h\uh' // a
]
...
is_deeply(decode_jkml(<<'...'), ['hogehoge', "h\\uh"]);
[
    r"hogehoge"/*
        heh
    */,
    r'h\uh' // a
]
...

done_testing;

