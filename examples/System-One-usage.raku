use v6.d;
use WWW::Ollama::Client;

# Requires Ollama 0.35+ and a locally pulled model: ollama pull nimble

say '=' x 100;
say 'Documentation example';
say '-' x 100;

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

#====================================================================================================
say "\n";
say '=' x 100;
say 'Machine Learning Workflows';
say '-' x 100;

my $message = q:to/END/;
Make a latenent semantic analysis pipeline over the texts aAbstracts, without stemming, and 25 NNMF-extracted topics.
END

$t0 = now;

$result = $client.system-one({
    model => 'nimble',
    state => { :$message },
    questions => {
        workflow => {
            type => 'choice',
            instructions => 'Choose the relevant workflow.',
            criteria => {
                SMRMon => 'Sparse Matrix Recommander',
                LSAMon => 'Latent Semantic Analyzer',
                ClCon => 'Contextual Classifier',
                QRMon => 'Quantile Regression Analyzer',
                DataWrangler => 'Data Manitpulation Query',
            },
        },
    },
});


$t1 = now;

say "answer: {$result<answers><workflow><choice>} in {$t1 - $t0} seconds";

#====================================================================================================
say "\n";
say '=' x 100;
say 'LSAMon parameters';
say '-' x 100;

$t0 = now;
$result = $client.system-one({
    model => 'nimble',
    state => { :$message },
    questions => {
        data => {
            type => 'choice',
            instructions => 'Which input data should the pipeline use?',
            criteria => {
                abstracts => 'The supplied text abstracts.',
                full-texts => 'The complete source documents.',
                titles => 'Only document titles.',
            },
        },
        method => {
            type => 'choice',
            instructions => 'Which topic-extraction method is requested?',
            criteria => {
                nnmf => 'Non-negative matrix factorization.',
                svd => 'Singular value decomposition.',
                ica => 'Independent component analysis.',
            },
        },
        number-of-topics => {
            type => 'choice',
            instructions => 'How many topics are requested?',
            criteria => { '10' => 'Ten topics.', '20' => 'Twenty topics.', '30' => 'Thirty topics.' },
        },
        stemming => {
            type => 'noul',
            instructions => 'Should stemming be used?',
            criteria => { true => 'Apply stemming.', false => 'Do not apply stemming.' },
        },
        min-number-of-documents-per-term => {
            type => 'choice',
            instructions => 'Choose the minimum document frequency for a retained term.',
            criteria => { '1' => 'Keep terms in one document.', '2' => 'Keep terms in at least two documents.', '5' => 'Keep terms in at least five documents.' },
        },
        max-steps => {
            type => 'choice',
            instructions => 'Choose the maximum number of topic-extraction iterations.',
            criteria => { '50' => 'Fifty iterations.', '100' => 'One hundred iterations.', '200' => 'Two hundred iterations.' },
        },
    },
});

$t1 = now;

my %answers = $result<answers>;
say "answer in {$t1 - $t0} seconds";
say "data: " ~ %answers<data><choice>;
say "method: " ~ %answers<method><choice>;
say "number-of-topics: " ~ %answers<number-of-topics><choice>;
say "stemming probability: " ~ %answers<stemming><noul>;
say "min-number-of-documents-per-term: " ~ %answers<min-number-of-documents-per-term><choice>;
say "max-steps: " ~ %answers<max-steps><choice>;
