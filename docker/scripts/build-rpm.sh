#!/bin/sh -ex

######################################################################
# TODO: ensure that it will build an RPM
# TODO: deposit the RPM to an s3 bucket
# TODO: add curl to update release saying work has begun
# TODO: add curl to update release saying work has finished
# TODO: make curls more robust
######################################################################

################################
# ENV vars used by this script #
################################

# REPO (event.body.repository.name)
# REPO_FULLNAME (event.body.repository.full_name)
# TARBALL_URL (event.body.release.tarball_url)
# VERSION (event.body.release.tag_name)
# GITHUB_USER (provided by ECS task env var)
# GITHUB_TOKEN (provided by ECS task env var)

#############
# variables #
#############

spec_file=${REPO}_rpm.spec
rpmbuild_dir=/home/builder/rpmbuild
source_dir=$rpmbuild_dir/SOURCES
spec_dir=$rpmbuild_dir/SPECS
rpm_dir=$rpmbuild_dir/RPMS

#################
# do the things #
#################

# download the src code to ${home}/rpmbuild/SOURCES
curl --location \
     --user $GITHUB_USER:$GITHUB_TOKEN \
     --output $source_dir/$VERSION.tar.gz \
     $TARBALL_URL

# download the spec file to ${home}/rpmbuild/SPECS
curl --location \
     --user $GITHUB_USER:$GITHUB_TOKEN \
     --header 'Accept: application/vnd.github.v3.raw' \
     --output $spec_dir/$spec_file \
     https://api.github.com/repos/$REPO_FULLNAME/contents/$spec_file?ref=tags/$VERSION

# install build dependencies
yum-builddep -y $spec_dir/$spec_file

# build the ruby rpms
rpmbuild -bb \
  --define "_version $VERSION" \
  --define "_source $TARBALL_URL" \
  --define "_repo $REPO" \
  $spec_dir/$spec_file

exit 0

# copy the rpms back to the shared mount
cp $HOME/rpmbuild/RPMS/x86_64/* /shared
cp $HOME/rpmbuild/SRPMS/* /shared
