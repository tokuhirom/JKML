use strict;
use warnings;
use utf8;
use Test::More;
use JKML::PP;

sub j {
    my $j = JKML::PP->new();
    my $ret = $j->decode(shift);
    unless ($ret) {
        die $j->error;
    }
    return $ret;
}

is_deeply(j(<<'...'), {});
{
}
...
is_deeply(JKML::PP->new->decode(<<'...'), ['hogehoge']);
[r"hogehoge"]
...
is_deeply(j(<<'...'), ['hogehoge', "h\\uh"]);
[
    r"hogehoge",
    r'h\uh' // a
]
...
is_deeply(j(<<'...'), ['hogehoge', "h\\uh"]);
[
    r"hogehoge"/*
        heh
    */,
    r'h\uh' // a
]
...

done_testing;

