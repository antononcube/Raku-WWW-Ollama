use v6.d;

use WWW::Ollama::HTTPClient;

# Client for the System One structured-decision HTTP API. This is separate from
# Ollama generation requests: System One neither streams nor manages a process.
class WWW::Ollama::SystemOne {
    has WWW::Ollama::HTTPClient $.http;
    has Str $.provider is rw = q[ollama];

    submethod BUILD(Str :$provider = 'ollama', Str :$base-url = '', Str :$api-key = '', :$http) {
        die 'System One provider must be ollama or hosted.' unless $provider eq any <ollama hosted>;
        $!provider = $provider;
        if $http.defined { $!http = $http; return; }
        if $provider eq 'hosted' {
            my $url = $base-url || (%*ENV<SYSTEM_ONE_BASE_URL> // 'https://system-one.dev/v1');
            my $key = $api-key || (%*ENV<SYSTEM_ONE_API_KEY> // '');
            $!http = WWW::Ollama::HTTPClient.new(:base-url($url), :api-key($key));
        } else {
            my $url = $base-url || 'http://127.0.0.1:11434';
            $!http = WWW::Ollama::HTTPClient.new(:base-url($url));
        }
    }

    method evaluate(%request is copy, Str :$idempotency-key = '') {
        self!validate-request(%request);
        %request<model> //= 'nimble' if $!provider eq 'ollama';
        my %headers;
        %headers<Idempotency-Key> = $idempotency-key if $idempotency-key.chars;
        my $path = $!provider eq 'ollama' ?? '/v1/systemone' !! '/systemone';
        self!shape($!http.post($path, %request, :%headers));
    }

    method models() {
        my $path = $!provider eq 'ollama' ?? '/api/tags' !! '/models';
        self!shape($!http.get($path));
    }

    method !validate-request(%request) {
        die 'System One request requires a state field.' unless %request<state>:exists;
        die 'System One request requires a non-empty questions hash.'
            unless %request<questions>:exists && %request<questions> ~~ Associative && %request<questions>.keys.elems;
        my $max-questions = $!provider eq 'ollama' ?? 64 !! 32;
        die "System One supports at most $max-questions questions for the selected provider."
            if %request<questions>.keys.elems > $max-questions;
        for %request<questions>.kv -> $name, $question {
            die 'System One question names must be non-blank strings.' unless $name ~~ Str:D && $name.trim.chars;
            die "System One question '$name' must be a hash." unless $question ~~ Associative;
            my $type = $question<type> // '';
            die "System One question '$name' has unsupported type '$type'."
                unless $type eq any <choice score noul>;
            if $type eq 'choice' {
                my $max-options = $!provider eq 'ollama' ?? 26 !! 255;
                die "System One choice '$name' requires 2 to $max-options criteria."
                    unless $question<criteria>:exists && $question<criteria> ~~ Associative
                        && $question<criteria>.keys.elems ~~ 2..$max-options;
            }
            if $type eq 'score' {
                my $max-levels = $!provider eq 'ollama' ?? 26 !! 10;
                die "System One score '$name' requires 2 to $max-levels criteria."
                    unless $question<criteria>:exists && $question<criteria> ~~ Positional
                        && $question<criteria>.elems ~~ 2..$max-levels;
            }
        }
    }

    method !shape(%response) {
        my %headers = %response<headers> // {};
        unless %response<success> {
            my $error = %response<decoded-content><error> // %response<reason> // 'unknown error';
            return { :$error, status => (%response<status> // 500), 'response-headers' => %headers };
        }
        my $data = %response<decoded-content> // {};
        return $data unless $data ~~ Associative;
        my %result = $data;
        my $request-id = %headers<X-Request-Id> // %headers<x-request-id>;
        my $credits = %headers<X-System-One-Credits> // %headers<x-system-one-credits>;
        %result<request-id> = $request-id if $request-id.defined;
        %result<credits> = $credits if $credits.defined;
        %result<response-headers> = %headers;
        %result;
    }
}
