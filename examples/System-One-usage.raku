use v6.d;
use WWW::Ollama::Client;

# Requires Ollama 0.35+ and a locally pulled model: ollama pull nimble
my $client = WWW::Ollama::Client.new(:ensure-running);
my $result = $client.system-one({
    model => 'nimble',
    state => { message => 'I was charged twice for one order.' },
    questions => {
        team => {
            type => 'choice',
            instructions => 'Choose the reviewing team.',
            criteria => {
                billing => 'Payments and refunds',
                support => 'Technical help',
            },
        },
    },
});
say $result<answers><team><choice>;
