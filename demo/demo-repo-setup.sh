#!/bin/bash

PROFILE=$(pwd)/demo/black-hat-demo-profile.yaml
PROFILE_NAME=black-hat-profile
PY_TEST_REPO=$(gh repo view --json name,owner --jq '.owner.login + "/" + .name')

# Check if we're logged in
minder auth whoami || minder auth login

# register the repos
# TODO: commented out to work around a bug in the event cache
# minder repo register --repo $PY_TEST_REPO --provider=github

# create the test profile
minder profile create -f $PROFILE

echo "Giving minder a couple of seconds to reconcile..."

# TODO: this could be a poll over the profile status to make sure it's not pending anymore...
sleep 5

# show the profile, should show failure now and open a open a Dependabot PR
minder profile_status list --provider=github -i $PROFILE_NAME -d

# show the security advisory, should exist now
security_advisory_url=$(gh api /repos/{owner}/{repo}/security-advisories | jq '.[] | select(.state == "draft") | .html_url' | tr -d \")
open $security_advisory_url

# list the PRs, there should be one for dependabot
dependabot_pr_url=$(gh pr list --json title,number,url --jq '.[] | select(.title | startswith("Add Dependabot configuration")) | .url' | tr -d \")
open $dependabot_pr_url

read -n 1 -s -p "opened PR and security advisory. Press a key when the PR has been merged"

# merge this PR, the profile should flip into success

#read -n 1 -s -p "press a key to merge the PR"
#dependabot_pr_num=$(gh pr list --json title,number,url --jq '.[] | select(.title | startswith("Add Dependabot configuration")) | .number')
#gh pr merge $dependabot_pr_num

echo "Giving minder a couple of seconds to reconcile..."
sleep 5

minder profile_status list --provider=github -i $PROFILE_NAME -d

# Trusty integration
# open a PR from the add_crequests branch
gh pr create --base main --head python-oauth2 --title 'add python-oauth2' --body 'adds python-oauth2'
trusty_pr_url=$(gh pr list --json title,number,url --jq '.[] | select(.title | startswith("add python-oauth2")) | .url' | tr -d \")
trusty_pr_num=$(gh pr list --json title,number,url --jq '.[] | select(.title | startswith("add python-oauth2")) | .number')
open $trusty_pr_url

read -n 1 -s -p "Press a key to close the PR and proceed"
gh pr close $trusty_pr_num

# show that the PR was commented on, show the links to trusty

# OSV integration
# open a PR from the add-vulnerable-requests branch
git push origin add-vulnerable-requests --force
gh pr create --base main --head add-vulnerable-requests --title 'add-vulnerable-requests' --body 'adds vulnerable requests'
osv_pr_url=$(gh pr list --json title,number,url --jq '.[] | select(.title | startswith("add-vulnerable-requests")) | .url' | tr -d \")
osv_pr_num=$(gh pr list --json title,number,url --jq '.[] | select(.title | startswith("add-vulnerable-requests")) | .number')
open $osv_pr_url

sleep 5

minder profile_status list --provider=github -i $PROFILE_NAME -d

read -n 1 -s -p "Press a key to close the PR and proceed"
gh pr close $osv_pr_num


# accept the suggestions, merge the PR show that it's passing now

read -n 1 -s -p "Press any key to exit"
