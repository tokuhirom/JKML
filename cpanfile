requires 'perl', '5.008001';
requires 'Types::Serializer';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'JSON::PP';
};

