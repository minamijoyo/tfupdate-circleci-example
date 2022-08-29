#!/usr/bin/env bash
set -eo pipefail

# https://gist.github.com/987Nabil/594764a7444cb5eee0636607d06f43c5

# MIT No Attribution

# Copyright 2022 Nabil Abdel-Hafeez

# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#!/usr/bin/env bash

appId=$APP_ID
secret=$APP_SECRET
repo=$GH_REPO

header='{ "typ": "JWT", "alg": "RS256" }'

payload="{ \"iss\": \"$appId\" }"

payload=$(
    echo "${payload}" | jq --arg time_str "$(date +%s)" \
    '
    ($time_str | tonumber) as $time_num
    | .iat=$time_num - 15
    | .exp=($time_num + 60 * 5)
    '
)


b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }
json() { jq -c . | LC_CTYPE=C tr -d '\n'; }
rs_sign() { openssl dgst -binary -sha256 -sign <(printf '%s\n' "$1"); }

signed_content="$(json <<<"$header" | b64enc).$(json <<<"$payload" | b64enc)"
sig=$(printf %s "$signed_content" | rs_sign "$secret" | b64enc)

installation_id=$(jq .id <<< "$(curl --location -g -s \
--request GET "https://api.github.com/repos/${repo}/installation" \
--header 'Accept: application/vnd.github.machine-man-preview+json' \
--header "Authorization: Bearer ${signed_content}.${sig}")")

unscoped_token=$(jq .token -r <<< "$(curl --location -g -s \
--request POST "https://api.github.com/app/installations/${installation_id}/access_tokens" \
--header 'Accept: application/vnd.github.v3+json' \
--header "Authorization: Bearer ${signed_content}.${sig}")")

repo_id=$(jq .id <<< "$(curl -g -s \
-H "Accept: application/vnd.github.v3+json" \
--header "Authorization: token $unscoped_token" \
"https://api.github.com/repos/$repo")")

token=$(jq .token -r <<< "$(curl --location -g -s \
--request POST "https://api.github.com/app/installations/${installation_id}/access_tokens" \
--header 'Accept: application/vnd.github.v3+json' \
--header "Authorization: Bearer ${signed_content}.${sig}" \
-d "{\"repository_ids\":[$repo_id]}" )")

echo "$token"
