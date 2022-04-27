#!/usr/bin/env bash

# This script will run regression tests for many earlier OpenStudio versions
# For a single & more interactive version use the CLI ./launch_docker.sh

# AUTHOR: Julien Marrec, julien@effibem.com, 2018

# Source the file that has the colors
source colors.sh

#######################################################################################
#                           H A R D C O D E D    A R G U M E N T S
#######################################################################################

# Do you want to ask the user to set these arguments?
# If false, will just use the hardcoded ones
ask_user=true

# If image custom/openstudio:$os_version already exists, do you want to force rebuild?
# Otherwise will use this one
force_rebuild=false

# Delete openstudio-build/centos:$os_version image after having used it?
delete_custom_image=false

# verbosity/debug mode.
verbose=false

# Maximum number of cores
# Defaults to all
n_cores=`nproc`


########################################################################################
#                               V A R I A B L E S
########################################################################################

# Image/Container names
centos_version=centos7    # Not planning to try and do a Dockerfile.in yet, so hardcoding
# # Prepare the dockerfile (string substitution in the template file)
# sed -e "s/\${centos_version}/$centos_version/" Dockerfile.in > Dockerfile
os_container_name=os-centos
os_image_name=openstudio-build/centos:$centos_version
base_os_image_name=centos/centos:$centos_version

# String representation with colors
os_container_str="${BBlue}container${Color_Off} ${UBlue}$os_container_name${Color_Off}"
os_image_str="${BRed}image${Color_Off} ${URed}$os_image_name${Color_Off}"
base_os_image_str="${BRed}image${Color_Off} ${URed}$base_os_image_name${Color_Off}"



########################################################################################
#                                     S E T U P
########################################################################################

if [ $(uname -m) == 'arm64' ]; then
  platform_flag="--platform linux/amd64"
  echo -e "arm64 detected: Will pass ${BRed}$platform_flag${Color_Off} to docker run"
fi

#######################################################################################
#                       G L O B A L    U S E R    A R G U M E N T S
########################################################################################

if [ "$ask_user" = true ]; then

  echo -e -n "Do you want to force rebuild for the $os_image_str? [y/${URed}N${Color_Off}] "
  read -n 1 -r
  echo    # (optional) move to a new line
  # Default is No
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    force_rebuild=true
  fi

  echo -e -n "Do you want to delete the $os_image_str after use? [y/${URed}N${Color_Off}] "
  read -n 1 -r
  echo    # (optional) move to a new line
  # Default is No
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    delete_custom_image=true
  fi

  echo -e -n "Do you want to enable the ${BCyan}verbose (debug) mode${Color_Off}? [y/${URed}N${Color_Off}] "
  read -n 1 -r
  echo    # (optional) move to a new line
  # Default is No
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    verbose=true
  fi

  echo -e -n "Do you want to limit the number of ${BRed}threads${Color_Off} available to docker? Current default is ${BRed}`nproc`${Color_Off} [y/${URed}N${Color_Off}] "
  read -n 1 -r
  echo    # (optional) move to a new line
  # Default is No
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -n "Please enter number: "
    read n_cores
    # Ensure it is a number (float or int)
    while ! [[ "$n_cores" =~ ^[0-9.]+$ ]]; do
      echo "Please enter an actual number!"
      read n_cores
    done
  fi

  echo "Global options have been set as follows:"
  echo "-----------------------------------------"
  echo "force_rebuild=$force_rebuild"
  echo "delete_custom_image=$delete_custom_image"
  echo "verbose=$verbose"
  echo "n_cores=$n_cores"
  echo
fi

# Verbosity
if [ "$verbose" = true ]; then
  OUT=/dev/stdout
else
  # Pipe output of docker commands to /dev/null to supress them
  OUT=/dev/null
fi

# For msys (mingw), do not do path conversions '/' -> windows path
if [[ "$(uname)" = MINGW* ]]; then
  if [ "$verbose" = true ]; then
    echo
    echo "Note: Windows workaround: setting MSYS_NO_PATHCONV to True when calling docker"
  fi
  docker()
  {
    export MSYS_NO_PATHCONV=1
    ("docker.exe" "$@")
    export MSYS_NO_PATHCONV=0
  }
fi

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

function delete_image() {
  # Arg 1 is the image_name
  # Arg 2 is the image_str with colors
  # Arg 3 is the linked container_name
  # Arg 4 is the default answer: pass Y for yes, N for no. Default N

  # eg: delete_image "$os_image_name" "$os_image_str" "$os_container_name" N

  # if the container still exists but it is stopped, delete?
 if [ ! "$(docker ps -aq -f name=$3)" ]; then
    if [[ $4 = Y ]]; then
      echo -e -n "Do you want to delete the $2? [${URed}Y${Color_Off}/n]? "
      read -n 1 -r
      echo    # (optional) move to a new line
      # Default is yes
      if [[ ! $REPLY =~ ^[Nn]$ ]]
      then
        docker rmi $1> $OUT
        echo -e "* Deleted the $2"
      fi
    else
      echo -e -n "Do you want to delete the $2? [y/${URed}N${Color_Off}]? "
      read -n 1 -r
      echo    # (optional) move to a new line
      # Default is no
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        docker rmi $1> $OUT
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

  # Cleanup custom/openstudio image?
  delete_image "$os_image_name" "$os_image_str" "$os_container_name" N

  if [[ "$(uname)" != MINGW* ]]; then
    echo
    echo -e "${On_Blue}Fixing ownership: setting it to user=$USER:$USER and chmod=664 (requires sudo)${Color_Off}"
    sudo chown -R $USER:$USER *
    sudo find ./dropbox/ -type f -exec chmod 664 {} \;
  fi

  exit $1

}


# trap ctrl-c and call cleanup()
trap cleanup INT


########################################################################################
#          B U I L D    O P E N S T U D I O    C U S T O M    I M A G E
########################################################################################


echo
echo -e "${On_Red}---------------------------------------------------------------${Color_Off}"
echo -e "${On_Red}              STARTING WITH A CENTOS VERSION: $centos_version          ${Color_Off}"
echo -e "${On_Red}---------------------------------------------------------------${Color_Off}"
echo

# We are going to use a Dockerfile to load the tagged nrel/openstudio image, then add some files, etc


# Prepare the dockerfile (string substitution in the template file)
# sed -e "s/\${centos_version}/$centos_version/" Dockerfile.in > Dockerfile

echo ""
# If the docker image doesn't already exists
if [ -z $(docker images -q $os_image_name) ]; then
  echo -e "* Building the $os_image_str from Dockerfile"
  echo "Command: docker build $platform_flag -t $os_image_name ."
  docker build $platform_flag -t $os_image_name .
else
  if [ "$force_rebuild" = true ];
  then
    echo -e "* Rebuilding the image $os_image_str from Dockerfile"
    docker rmi $os_image_name > $OUT
    echo "Command: docker build $platform_flag -t $os_image_name ."
    docker build $platform_flag -t $os_image_name .
  fi
  echo
fi

# Execute a container in detached mode
# Check first if there is an existing one, and tell user what to do
if [ "$(docker ps -aq -f name=$os_container_name)" ]; then
  echo -e "Warning: The $os_container_str is already running... Stopping"
  docker stop $os_container_name > $OUT
fi

echo -e "* Launching the $os_container_str"
echo "Command: docker run --name $os_container_name --cpus="$n_cores" $platform_flag -v `pwd`/dropbox:/root/dropbox -d -it $os_image_name /bin/bash > $OUT"
docker run --name $os_container_name --cpus="$n_cores" $platform_flag -v `pwd`/dropbox:/root/dropbox -d -it $os_image_name /bin/bash > $OUT

# Chmod execute the script
docker exec $os_container_name chmod +x docker_container_script.sh

# Execute it
# Launch the regression tests
echo -e -n "Do you want to launch the build? [${URed}Y${Color_Off}/n] "
read -n 1 -r
echo    # (optional) move to a new line
# Default is yes
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
  echo -e "\nRunning docker_container_script.sh:"
  echo "------------------------------------"
  docker exec $os_container_name /bin/bash --login ./docker_container_script.sh
fi


# Attach to the container
echo -e -n "Do you want to attach to the running $os_container_str? [${URed}Y${Color_Off}/n] "
read -n 1 -r
echo    # (optional) move to a new line
# Default is yes
if [[ ! $REPLY =~ ^[Nn]$ ]]
then
  if [[ "$(uname)" = MINGW* ]]; then
    winpty docker attach $os_container_name
  else
    docker attach $os_container_name
  fi
fi



# Run cleanup when normal execution
cleanup 0

# docker run --name os-centos -it --platform linux/amd64 -v "$(pwd)/OpenStudio":/home/OpenStudio -v "$(pwd)/EnergyPlus":/home/EnergyPlus centos:centos7 /bin/bash

# Test one
# docker run --name os-centos-test -it --rm --platform linux/amd64 -v "$(pwd)":/home/OS-Centos centos:centos7 /bin/bash
