FROM docker.pkg.github.com/maki-project/docker-core/core:1.0.2


ARG PYTHON_VERSION
ARG PYTHON_FULL_VERSION
ARG PYTHON_SHA256SUM
ENV PYTHON_VERSION=${PYTHON_VERSION}
ENV PYTHON_FULL_VERSION=${PYTHON_FULL_VERSION}
ENV PYTHON_SHA256SUM=${PYTHON_SHA256SUM}

ENV PYTHON_BUILD_DEPENDENCIES="\
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    zlib-devel \
    sqlite-devel \
    readline-devel \
    ncurses-devel \
    xz-devel \
    tk-devel \
    gdbm-devel"

ENV PYTHON_RUNTIME_DEPENDENCIES="\
    gcc \
    libpq-devel \
    libxml2-devel \
    libxslt-devel"

RUN \
    echo " ---> Update system packages" && \
    dnf update -qy && \
    echo " ---> Added PostgreSQL repo" && \
    dnf -qy install 'dnf-command(config-manager)' && \
    dnf -qy config-manager --set-enabled PowerTools && \
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf -qy module disable postgresql && \
    echo " ---> Install required system packages" && \
    dnf install -y ${PYTHON_BUILD_DEPENDENCIES} ${PYTHON_RUNTIME_DEPENDENCIES} && \
    echo " ---> Download Python sources" && \
    cd /tmp && \
    curl -sSLO https://www.python.org/ftp/python/${PYTHON_FULL_VERSION}/Python-${PYTHON_FULL_VERSION}.tgz && \
    echo " ---> Verify Python source" && \
    echo "${PYTHON_SHA256SUM} Python-${PYTHON_FULL_VERSION}.tgz" | sha256sum -c && \
    tar -xf Python-${PYTHON_FULL_VERSION}.tgz && \
    cd Python-${PYTHON_FULL_VERSION} && \
    echo " ---> Build and install Python" && \
    ./configure --enable-optimizations --with-lto && \
    make altinstall && \
    ln -s /usr/local/bin/python${PYTHON_VERSION} /usr/local/bin/python3 && \
    python3 -m pip install --no-cache-dir --upgrade pip && \
    echo " ---> Cleanup" && \
    dnf erase -y ${PYTHON_BUILD_DEPENDENCIES} && \
    dnf clean all && \
    rm -rf /tmp/Python*

# Set correct uid:gid for extra directories (recursive)
#ENV CORE_EXTRA_PERMISSIONS="/root/docker/.cache/pip"

ONBUILD ARG DNF_EXTRA_PACKAGES=""
ONBUILD ENV DNF_EXTRA_PACKAGES=${DNF_EXTRA_PACKAGES}
ONBUILD RUN if [ ! -z "${DNF_EXTRA_PACKAGES}" ]; then \
                echo " ---> Install extra packages" && \
                dnf install -y ${DNF_EXTRA_PACKAGES} && \
                dnf clean all \
            ; fi
