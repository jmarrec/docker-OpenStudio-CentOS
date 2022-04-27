FROM centos:centos7

#RUN useradd -m oscentos
#USER oscentos

ENV PATH="/root/Qt/QtIFW-4.3.0/bin/:${PATH}" CC="/opt/rh/devtoolset-10/root/usr/bin/gcc" CXX="/opt/rh/devtoolset-10/root/usr/bin/g++"

# Chained into a single run statement to mimize the number of image layers
# The perl-Data-Dumper / perl-Thread-Queue are so you can build swig correctly
RUN yum -y update &&\
    yum install -y centos-release-scl epel-release && yum install -y devtoolset-10-gcc* &&\
    echo "source scl_source enable devtoolset-10" >> /etc/bashrc &&\
    source scl_source enable devtoolset-10 &&\
    yum install -y python3 patch git make which wget redhat-lsb-core perl-Data-Dumper perl-Thread-Queue libicu libicu-devel readline-devel rpm-build &&\
    pip3 install conan cmake ninja &&\
    conan profile new --detect default &&\
    conan profile update settings.compiler.libcxx=libstdc++ default &&\
    conan config set general.revisions_enabled=True && conan config set general.parallel_download=8 &&\
    echo "Installing QtIFW" &&\
    mkdir ~/Qt && cd ~/Qt &&\
    yum install -y xcb-util-wm xcb-util-image xcb-util-keysyms xcb-util-renderutil libxkbcommon-x11 fontconfig libX11 libXext libGL &&\
    wget --no-check-certificate https://download.qt.io/official_releases/qt-installer-framework/4.3.0/QtInstallerFramework-linux-x64-4.3.0.run &&\
    wget --no-check-certificate https://raw.githubusercontent.com/openstudiocoalition/OpenStudioApplication/develop/ci/install_script_qtifw.qs &&\
    chmod +x QtInstallerFramework-linux-x64-4.3.0.run &&\
    ./QtInstallerFramework-linux-x64-4.3.0.run --verbose --platform minimal --script install_script_qtifw.qs &&\
    echo '' >> ~/.bashrc &&\
    echo '# Setting the PS1 Prompt' >> ~/.bashrc &&\
    echo 'COLOR_0="0:37m" # Light Gray' >> ~/.bashrc &&\
    echo 'COLOR_1="38;5;167m" # Some light red' >> ~/.bashrc &&\
    echo 'COLOR_2="38;5;33m" # Some light blue' >> ~/.bashrc &&\
    echo 'PS1="\[\033[$COLOR_0\]\[\033[$COLOR_1\]\u\[\033[0m\]@\[\033[$COLOR_2\]\W\[\033[0m\]$ "' >> ~/.bashrc &&\
    echo "Installing Ruby 2.7.2 via RVM" &&\
    gpg2 --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BD &&\
    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import &&\
    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - &&\
    curl -sSL https://get.rvm.io | bash -s stable &&\
    sudo usermod -a -G rvm $USER &&\
    source /etc/profile.d/rvm.sh &&\
    rvm install 2.7.2 -- --enable-static &&\
    rvm --default use 2.7.2


WORKDIR /root

# Given that I have used a .dockerignore file, I don't need to specify which files to add, I can add the entire current directory
# And given that I have already set the WORKDIR, I can use relative path
# ADD . .
