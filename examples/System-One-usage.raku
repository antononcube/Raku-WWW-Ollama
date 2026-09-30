use v6.d;
use WWW::Ollama::Client;

# Requires Ollama 0.35+ and a locally pulled model: ollama pull nimble
my $client = WWW::Ollama::Client.new(:ensure-running);

my $t0 = now;

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

my $t1 = now;

say "answer: {$result<answers><team><choice>} in {$t1 - $t0} seconds";
