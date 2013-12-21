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
[raw(hogehoge)]
...
is_deeply(decode_jkml(<<'...'), ['hogehoge', "h\\uh"]);
[
    raw(hogehoge),
    raw(h\uh) # a
]
...
is_deeply(decode_jkml(<<'...'), 'hogehoge');
raw{hogehoge}
...
is_deeply(decode_jkml(<<'...'), 'hoge');
base64(aG9nZQ==)
...
is_deeply(decode_jkml(<<'...'), [1,1]);
[
    raw(1), raw[1],
]
...
is_deeply(decode_jkml(<<'...'), { b => 2 });
{
    b => 2,

}
...
is_deeply(decode_jkml(<<'...'), "I'm here");
<<-HERE
I'm here
HERE
...

is_deeply(decode_jkml(<<'...'), { foo => "I'm here" });
{
    foo => <<-HERE,
    I'm here
    HERE
}
...

done_testing;

