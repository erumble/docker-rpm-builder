FROM centos:6
MAINTAINER "Eric Rumble"

# create builder user and group per rpmbuild's recommendation
ENV home /root
RUN mkdir -p ${home}/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
WORKDIR ${home}

# add custom yum repo
COPY resources/fnrpms.repo /etc/yum.repos.d/

# Ensure the container is up to date
RUN yum makecache fast \
 && yum update -y \
 && yum install -y \
        rpm-build \
        yum-utils \
 && yum clean all

# Install the AWS CLI
ADD https://bootstrap.pypa.io/get-pip.py .
RUN chmod 644 ./get-pip.py \
 && python get-pip.py \
 && pip install awscli

ADD https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 .
RUN chmod +x jq-linux64 \
 && ln -s ${home}/jq-linux64 /usr/local/bin/jq

# drop the rpm-build script and spec file
COPY scripts/build-rpm.sh .
RUN chmod +x build-rpm.sh \
 && ln -s ${home}/build-rpm.sh /usr/local/bin/build-rpm

# set the entry point to build-rpm.sh so we can just docker run <container>
ENTRYPOINT ["build-rpm"]
