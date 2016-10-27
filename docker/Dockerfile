FROM centos:6
MAINTAINER "Eric Rumble"

# create builder user and group per rpmbuild's recommendation
ENV home /home/builder
RUN useradd -u 1000 builder \
 && mkdir -p ${home}/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS} \
 && chown -R builder:builder ${home}
WORKDIR ${home}

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

# drop the rpm-build script and spec file
COPY scripts/build-rpm.sh .
RUN chmod 755 ./build-rpm.sh \
 && ln -s ${home}/build-rpm.sh /usr/local/bin/build-rpm

# set the entry point to build-rpm.sh so we can just docker run <container>
ENTRYPOINT ["build-rpm"]
