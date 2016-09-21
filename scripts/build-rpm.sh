#!/bin/sh -eux

######################################################################
# TODO: Edit this file so that it builds an RPM based on some inputs #
######################################################################

# download the ruby source code
ruby_semver=`grep "%define \+ruby_ver" $HOME/rpmbuild/SPECS/ruby.spec | awk '{print $3}'`
cd $HOME/rpmbuild/SOURCES && curl -O ftp://ftp.ruby-lang.org/pub/ruby/ruby-$ruby_semver.tar.gz

# install build dependencies
yum-builddep -y $spec_file
# build the ruby rpms
rpmbuild -bb --define "_ruby_ver $ruby_semver" $spec_file

# copy the rpms back to the shared mount
cp $HOME/rpmbuild/RPMS/x86_64/* /shared
cp $HOME/rpmbuild/SRPMS/* /shared
