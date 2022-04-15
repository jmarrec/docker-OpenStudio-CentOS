# docker-OpenStudio-CentOS

A repo with configuring a docker image for centos and building openstudio with it

Usage:

```shell
./run_build.sh
```

You will be prompted to specify options.

Make sure you do not pass an nproc > where in your docker settings.json file.

(eg on mac: `jq -r '.cpus'  ~/Library/Group\ Containers/group.com.docker/settings.json`)

## Explanation of required steps

I have built:

* ruby_installer/2.7.3@nrel/centos from https://github.com/jmarrec/conan-ruby_installer/tree/testing/2.7.3 and uploaded it to NREL's conan remote
* openstudio_ruyb/2.7.2@nrel/centos from https://github.com/NREL/conan-openstudio-ruby/tree/centos using that patched ruby_installer and uploaded it to NREL's conan remote
* I am using this OpenStudio branch: https://github.com/NREL/OpenStudio/tree/CentOS that uses those installers and does some extra shenanigans with respect to CentOS config

The [Dockerfile](Dockerfile) will install needed dependencies and tools via `yum` and clone the git branch (TODO: move the clone in the docker_container_script.sh instead?)
The [docker_container_script.sh](docker_container_script.sh) is executed inside the container and will call `cmake` with the right options and then `ninja`

The docker container will share the host folder `./dropbox/`, and eventually will place the built artifact there
