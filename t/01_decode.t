use strict;
use warnings;
use utf8;
use Test::More;
use JKML::PP;
use JSON::PP;

# run author/testdata.pl for update test cases.

open my $fh, '<', 't/data.json'
    or die "Cannot open t/data.json for reading: $!";
my $json = do { local $/; <$fh> };
my @tests = @{JSON::PP::decode_json($json)};

while (my ($jkml, $data) = splice @tests, 0, 2) {
    is_deeply(decode_jkml($jkml), $data, $jkml);
}

done_testing;

