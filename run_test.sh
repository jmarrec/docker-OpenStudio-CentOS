#!/usr/bin/env bash

# This script will run regression tests for many earlier OpenStudio versions
# For a single & more interactive version use the CLI ./launch_docker.sh

# AUTHOR: Julien Marrec, julien@effibem.com, 2022

# Source the file that has the colors
source colors.sh

########################################################################################
#                               V A R I A B L E S
########################################################################################

# Image/Container names
os_container_name=test-os-centos
base_os_image_name=amazonlinux:2023

# String representation with colors
os_container_str="${BBlue}container${Color_Off} ${UBlue}$os_container_name${Color_Off}"
base_os_image_str="${BRed}image${Color_Off} ${URed}$base_os_image_name${Color_Off}"


OUT=/dev/stdout


########################################################################################
#                           C L E A N    U P
########################################################################################

# This is defined here because I also run this when I catch CTRL+C
# It is also run at the end of the normal execution

# Note: There should be no need to clean up the container as long as you attach to it,
# I use --rm when launching the container

function stop_running_container() {
  # Arg 1 is the container_name
  # Arg 2 is the container_str with colors
  # Arg 3 is the default answer: pass Y for yes, N for no. Default Y
  # eg: stop_running_container "$os_container_name" "$os_container_str" N

  # If the container is still running, ask whether we stop it first
  if [ "$(docker ps -q -f name=$1)" ]; then
    if [[ $3 = N ]]; then
      echo -e -n "Do you want to stop the running $2? [y/${URed}N${Color_Off}] "
      read -n 1 -r
      echo    # (optional) move to a new line
      # Default is No
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        docker stop $1> $OUT
        echo -e "* Stopped the $2"
      else
        echo -e "* You can attach to the running container by typing '${Green}docker attach $1'${Color_Off}"
      fi
    else

      echo -e -n "Do you want to stop the running $2? [${URed}Y${Color_Off}/n] "
      read -n 1 -r
      echo    # (optional) move to a new line
      # Default is yes
      if [[ ! $REPLY =~ ^[Nn]$ ]]
      then
        docker stop $1> $OUT
        echo -e "* Stopped the $2"
      else
        echo -e "* You can attach to the running container by typing '${Green}docker attach $1'${Color_Off}"
      fi
    fi
  fi
}

function delete_stopped_container() {
  # Arg 1 is the container_name
  # Arg 2 is the container_str with colors
  # eg: delete_stopped_container "$os_container_name" "$os_container_str"


  # if the container still exists but it is stopped, delete?
  if [ ! "$(docker ps -q -f name=$1)" ]; then
    if [ "$(docker ps -aq -f status=exited -f name=$1)" ]; then
      # cleanup?
      echo -e "The $2 is stopped but still present"
      read -p "Do you want to delete the $1? [${URed}Y${Color_Off}/n] " -n 1 -r
      echo    # (optional) move to a new line
      # Default is yes
      if [[ ! $REPLY =~ ^[Nn]$ ]]
      then
        docker rm $1> $OUT
        echo -e "* Deleted the $2"
      fi
    fi
  fi
}

function cleanup() {

  # ARG 1 is the exit code, 0 for normal, 1 for ctrl_c
  echo
  echo "Cleaning up:"

  # If the container is still running, ask whether we stop it first
  #if [ "$(docker ps -q -f name=$os_container_name)" ]; then
    #echo -e -n "Do you want to stop the running $os_container_str? [${URed}Y${Color_Off}/n] "
    #read -n 1 -r
    #echo    # (optional) move to a new line
    ## Default is yes
    #if [[ ! $REPLY =~ ^[Nn]$ ]]
    #then
      #docker stop $os_container_name
    #else
      #echo -e "You can attach to the running container by typing '${Green}docker attach $os_container_name'${Color_Off}"
    #fi
  #fi

  # If the openstudio container is still running, stop it? Defaults to Yes
  stop_running_container "$os_container_name" "$os_container_str" Y

  # Note: It's possible we don't get in there for the container really,
  # because I may have used --rm when 'run' so if you stop -> it's gone
  delete_stopped_container "$os_container_name" "$os_container_str"

  exit $1
}


# trap ctrl-c and call cleanup()
trap cleanup INT



########################################################################################
#                            T E S T    I N S T A L L E R
########################################################################################

echo -e "* Launching the $os_container_str"
echo "docker run --name $os_container_name -v `pwd`/dropbox:/root/dropbox -it --rm -d $base_os_image_name /bin/bash"
docker run --name $os_container_name -v `pwd`/dropbox:/root/dropbox -it --rm -d $base_os_image_name /bin/bash > $OUT

echo "${Cyan}yum localinstall -y OpenStudio-3.4.0-*.rpm${Color_Off}"
docker exec $os_container_name /bin/bash -c "cd /root/dropbox && yum localinstall -y OpenStudio-3.10.0-*.rpm"

echo -e "${BGreen}Install worked${Color_Off}"
echo ""

echo "${Cyan}Checking installed openstudio --version${Color_Off}"
docker exec $os_container_name /bin/bash -c "openstudio --version"
echo ""

echo "${Cyan}Get Install prefix:${Color_Off}"
install_root=$(docker exec $os_container_name /bin/bash -c "openstudio -e 'puts OpenStudio::getOpenStudioCLI.parent_path.parent_path.to_s'")
echo -e "install_root=${BGreen}$install_root${Color_Off}"
echo ""


echo -e "${BPurple}Trying to run a simulation${Color_Off}"
echo -e "openstudio run -w $install_root/Examples/compact_osw/compact.osw"
echo ""
docker exec $os_container_name /bin/bash -c "openstudio run -w $install_root/Examples/compact_osw/compact.osw"
echo ""
echo -e "${Cyan}eplusout.err:${Color_Off}"
docker exec $os_container_name /bin/bash -c "head -n2 $install_root/Examples/compact_osw/run/eplusout.err"
echo -e "${Cyan}     [  ... truncated ... ]${Color_Off}"
docker exec $os_container_name /bin/bash -c "tail -n3 $install_root/Examples/compact_osw/run/eplusout.err"

# Run cleanup when normal execution
cleanup 0
