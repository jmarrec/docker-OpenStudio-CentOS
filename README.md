# docker-OpenStudio-CentOS

A repo with configuring a docker image for centos and building openstudio with it

Usage:

```shell
./run_build.sh
```

You will be prompted to specify options.

Make sure you do not pass an nproc > where in your docker settings.json file.

(eg on mac: `jq -r '.cpus'  ~/Library/Group\ Containers/group.com.docker/settings.json`)
