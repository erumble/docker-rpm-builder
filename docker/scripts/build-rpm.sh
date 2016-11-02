#!/bin/sh -eu

######################################################################
# TODO: deposit the RPM to an s3 bucket
# TODO: handle errors
# TODO: make it idempotent
######################################################################

################################
# ENV vars used by this script #
################################

# RELEASE (event.body.release)
# REPOSITORY (event.body.repository)

# GITHUB_USER (provided by ECS task env var)
# GITHUB_TOKEN (provided by ECS task env var)

#############
# functions #
#############

function get_json_value {
  jq -r -n --argjson json "$1" --arg val "$2" '$json | ."\($val)"'
}

function create_release_body {
  jq -n --argjson json "$1" --arg message "$2" \
    '$json | {tag_name, target_commitish, name, body: "\(.body)\($message)", draft, prerelease}' | \
    sed 's/\\\\/\\/g'
}

function patch_release {
  curl \
    --data "$1" \
    --header 'Content-Type: application/json' \
    --location \
    --output /dev/null \
    --request PATCH \
    --retry 3 \
    --silent \
    --user $GITHUB_USER:$GITHUB_TOKEN \
    --write-out "%{http_code}\\n" \
    https://api.github.com/repos/$repo_fullname/releases/$release_id
}

function upload_file_to_release {
  asset_name="${1##*/}"

  curl \
    --data-binary @$1 \
    --header "Content-Type: $(file -b --mime-type $1)" \
    --request POST \
    --retry 3 \
    --user $GITHUB_USER:$GITHUB_TOKEN \
    https://uploads.github.com/repos/$repo_fullname/releases/$release_id/assets?name=$asset_name
}

#############
# variables #
#############

release_id=$(get_json_value "$RELEASE" "id")
version=$(get_json_value "$RELEASE" "tag_name")
name=$(get_json_value "$RELEASE" "name")
tarball_url=$(get_json_value "$RELEASE" "tarball_url")

repo=$(get_json_value "$REPOSITORY" "name")
repo_fullname=$(get_json_value "$REPOSITORY" "full_name")

spec_file=${repo}_rpm.spec
rpmbuild_dir=/root/rpmbuild
source_dir=$rpmbuild_dir/SOURCES
spec_dir=$rpmbuild_dir/SPECS
rpm_dir=$rpmbuild_dir/RPMS

############################################
# Update release to show build has started #
############################################

build_start_message="\r\n\r\nBuild Info\r\n----------\r\nBuild started on $(date)"
build_start_body=$(create_release_body "$RELEASE" "$build_start_message")
patch_release "$build_start_body"

#################
# build the rpm #
#################

# download the src code to ${home}/rpmbuild/SOURCES
curl --location \
  --retry 3 \
  --user $GITHUB_USER:$GITHUB_TOKEN \
  --output $source_dir/$version.tar.gz \
  https://github.com/$repo_fullname/archive/$version.tar.gz

# download the spec file to ${home}/rpmbuild/SPECS
curl --location \
  --retry 3 \
  --user $GITHUB_USER:$GITHUB_TOKEN \
  --header 'Accept: application/vnd.github.v3.raw' \
  --output $spec_dir/$spec_file \
  https://api.github.com/repos/$repo_fullname/contents/$spec_file?ref=tags/$version

# install build dependencies
yum-builddep -y $spec_dir/$spec_file

# build the rpm
rpmbuild -bb \
  --define "_version $version" \
  --define "_source $tarball_url" \
  --define "_repo $repo" \
  $spec_dir/$spec_file

rpm_build_code=$?

#############################################
# update release to show build has finished #
#############################################

if [ $rpm_build_code -eq 0 ]; then
  build_finished_message="\r\nBuild finisehd on $(date)\r\n\r\n#### MD5 Sums"
  for rpm in $(find $rpm_dir -type f -name *.rpm); do
    build_finished_message=$build_finished_message"\r\n* $(openssl md5 $rpm | awk -F '[ /)]' '{print $6 " - " $8 "\n"}')"
    upload_file_to_release $rpm
  done
else
  build_finished_message="\r\nBuild FAILED on $(date)"
fi

build_finished_body=$(create_release_body "$build_start_body" "$build_finished_message")
patch_release "$build_finished_body"
