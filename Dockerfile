FROM centos:centos7

#RUN useradd -m oscentos
#USER oscentos
ENV PATH="/root/Qt/QtIFW-4.6.1/bin/:${PATH}" CC="/opt/rh/devtoolset-10/root/usr/bin/gcc" CXX="/opt/rh/devtoolset-10/root/usr/bin/g++"

COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

# Chained into a single run statement to mimize the number of image layers
# The perl-Data-Dumper / perl-Thread-Queue are so you can build swig correctly
RUN yum clean plugins && yum clean all && yum -y update &&\
    yum install -y centos-release-scl epel-release && yum install -y devtoolset-10-gcc* &&\
    echo "source scl_source enable devtoolset-10" >> /etc/bashrc &&\
    source scl_source enable devtoolset-10 &&\
    yum install --nogpgcheck -y rh-python38 rh-python38-python-devel patch git make which wget redhat-lsb-core perl-Data-Dumper perl-Thread-Queue libicu libicu-devel readline-devel rpm-build libgomp libX11 \
                mesa-libGLES.x86_64 mesa-libGL-devel.x86_64 mesa-libGLU-devel.x86_64 mesa-libGLw.x86_64 mesa-libGLw-devel.x86_64 libXi-devel.x86_64 freeglut-devel.x86_64 freeglut.x86_64 \
                libXrandr libXrandr-devel libXinerama-devel libXcursor-devel glibc-static &&\
    echo "source scl_source enable rh-python38 " >> /etc/bashrc &&\
    source scl_source enable rh-python38 &&\
    pip3 install conan>2 cmake ninja &&\
    conan profile detect &&\
    sed -i.bak 's/compiler.libcxx=.*$/compiler.libcxx=libstdc++/g' $HOME/.conan2/profiles/default &&\
    sed -i.bak 's/cppstd=.*$/cppstd=20/g' $HOME/.conan2/profiles/default &&\
    echo "core:non_interactive = True" >> $HOME/.conan2/global.conf  &&\
    echo "core.download:parallel = {{os.cpu_count() - 2}}" >> $HOME/.conan2/global.conf &&\
    echo "core.sources:download_cache = $HOME/.conan-download-cache" >> $HOME/.conan2/global.conf  &&\
    echo "Installing QtIFW" &&\
    mkdir ~/Qt && cd ~/Qt &&\
    yum install -y xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil libxkbcommon-x11 fontconfig libXext libGL &&\
    wget --no-check-certificate https://download.qt.io/official_releases/qt-installer-framework/4.6.1/QtInstallerFramework-linux-x64-4.6.1.run &&\
    chmod +x QtInstallerFramework-linux-x64-4.6.1.run &&\
    ./QtInstallerFramework-linux-x64-4.6.1.run --accept-licenses --default-answer --confirm-command install &&\
    echo '' >> ~/.bashrc &&\
    echo '# Setting the PS1 Prompt' >> ~/.bashrc &&\
    echo 'COLOR_0="0:37m" # Light Gray' >> ~/.bashrc &&\
    echo 'COLOR_1="38;5;167m" # Some light red' >> ~/.bashrc &&\
    echo 'COLOR_2="38;5;33m" # Some light blue' >> ~/.bashrc &&\
    echo 'PS1="\[\033[$COLOR_0\]\[\033[$COLOR_1\]\u\[\033[0m\]@\[\033[$COLOR_2\]\W\[\033[0m\]$ "' >> ~/.bashrc &&\
    yum install -y rh-ruby27 &&\
    echo "source scl_source enable rh-ruby27" >> /etc/bashrc &&\
    source scl_source enable rh-ruby27
#    echo "Installing Ruby 2.7.2 via RVM" &&\
#    gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BD &&\
#    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import &&\
#    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - &&\
#    curl -sSL https://get.rvm.io | bash -s stable &&\
#    sudo usermod -a -G rvm $USER &&\
#    source /etc/profile.d/rvm.sh &&\
#    rvm install 2.7.2 -- --enable-static &&\
#    rvm --default use 2.7.2

# Install python from pyenv
ARG PYTHON_VERSION=3.12.2
RUN yum install -y patch zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl11-devel tk-devel libffi-devel xz-devel \
    && curl https://pyenv.run | bash \
    && CPPFLAGS="$(pkg-config --cflags openssl11)" LDFLAGS="$(pkg-config --libs openssl11)" PYTHON_CONFIGURE_OPTS="--enable-shared" /root/.pyenv/bin/pyenv install ${PYTHON_VERSION} \
    && /root/.pyenv/bin/pyenv global ${PYTHON_VERSION} \
    && echo '[[ -s "$HOME/.pyenv/bin" ]] && eval "$($HOME/.pyenv/bin/pyenv init -)"' >> ~/.bashrc

# Install ruby from rbenv
ARG RUBY_VERSION=3.2.2
RUN yum install -y patch bzip2 openssl-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel tar libyaml-devel perl-IPC-Cmd \
    && curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash \
    && echo '[[ -s "$HOME/.rbenv/bin" ]] && eval "$($HOME/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc

# Can't manage to run this from the dockerfile, but it works inside the container...
#RUN RUBY_CONFIGURE_OPTS="--disable-shared" $HOME/.rbenv/bin/rbenv install ${RUBY_VERSION} || cat /tmp/ruby-build.*.log \
#    && $HOME/.rbenv/bin/rbenv global ${RUBY_VERSION}

# perl-Digest-SHA1

WORKDIR /root

# Given that I have used a .dockerignore file, I don't need to specify which files to add, I can add the entire current directory
# And given that I have already set the WORKDIR, I can use relative path
# ADD . .
