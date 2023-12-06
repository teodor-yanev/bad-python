#!/bin/bash


PROFILE=$(pwd)/demo/black-hat-demo-profile.yaml

# Check if we're logged in
minder auth whoami || minder auth login

echo "This will DELETE ALL YOUR PROFILES and UNREGISTER ALL YOUR REPOS"

read -n 1 -s -p "Press any key to continue or Ctrl+C to exit"

profile_id_list=$(minder profile list --provider=github -ojson | jq 'if .profiles then .profiles[].id else empty end')
for id in $profile_id_list; do
   minder profile delete -i $id;
done

# to anyone reading my JQ code - I am sorry.
# also the tr that removes quoting could probably be removed if I could get the JQ query working w/o quotes
repo_list=$(minder repo list --provider github --output=json | jq '.[] | .[] |  "\(.owner)/\(.name)"' | tr '\n' ' ' | tr -d \")
for repo in $repo_list; do
   minder repo delete -n $repo --provider github
done

for pr_num in $(gh pr list --state open --limit 1000 | awk '{print $1}'); do
    gh pr close $pr_num
done

gh api -X DELETE /repos/{owner}/{repo}/branches/{branch}/protection

git checkout main
git reset --hard restore
git push origin main --force
