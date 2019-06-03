#!/bin/bash

GIT_COMMIT=$(git log origin/test | head -1)
COMMIT_SHA=${GIT_COMMIT/commit /}
echo "COMMIT = $COMMIT_SHA"


STATUS=success
LABEL="Test Coverage"
DESCRIPTION=$(date)

# curl_data(){
#   CAT <<EOF
# {
#   "state": "${STATUS}",
#   "target_url": "https://pypi.org/project/bandit/",
#   "description": "Test coverage 76%, previous 74%",
#   "context": "${LABEL}"
# }
# EOF
# }

# curl -X GET https://api.github.com/repos/shanee-spring/learning_jenkins/statuses/${COMMIT_SHA}

curl -X POST https://api.github.com/repos/shanee-spring/learning_jenkins/statuses/${COMMIT_SHA}?access_token=${TOKEN} \
-d "{\"state\": \"${STATUS}\", \"target_url\": \"https://pypi.org/project/bandit/\", \"description\": \"${DESCRIPTION}\", \"context\": \"local\"}"

# curl -X GET https://api.github.com/repos/shanee-spring/learning_jenkins/commits/${COMMIT_SHA}/statuses
