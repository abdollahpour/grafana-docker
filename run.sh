#!/bin/bash -e

PERMISSIONS_OK=0

if [ ! -r "$GF_PATHS_CONFIG" ]; then
    echo "GF_PATHS_CONFIG='$GF_PATHS_CONFIG' is not readable."
    PERMISSIONS_OK=1
fi

if [ ! -w "$GF_PATHS_DATA" ]; then
    echo "GF_PATHS_DATA='$GF_PATHS_DATA' is not writable."
    PERMISSIONS_OK=1
fi

if [ ! -r "$GF_PATHS_HOME" ]; then
    echo "GF_PATHS_HOME='$GF_PATHS_HOME' is not readable."
    PERMISSIONS_OK=1
fi

if [ $PERMISSIONS_OK -eq 1 ]; then
    echo "You may have issues with file permissions, more information here: http://docs.grafana.org/installation/docker/#migration-from-a-previous-version-of-the-docker-container-to-5-1-or-later"
fi
 

if [ ! -z ${GF_AWS_PROFILES+x} ]; then
    mkdir -p "$GF_PATHS_HOME/.aws/"
    > "$GF_PATHS_HOME/.aws/credentials"

    for profile in ${GF_AWS_PROFILES}; do
        access_key_varname="GF_AWS_${profile}_ACCESS_KEY_ID"
        secret_key_varname="GF_AWS_${profile}_SECRET_ACCESS_KEY"
        region_varname="GF_AWS_${profile}_REGION"

        if [ ! -z "${!access_key_varname}" -a ! -z "${!secret_key_varname}" ]; then
            echo "[${profile}]" >> "$GF_PATHS_HOME/.aws/credentials"
            echo "aws_access_key_id = ${!access_key_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
            echo "aws_secret_access_key = ${!secret_key_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
            if [ ! -z "${!region_varname}" ]; then
                echo "region = ${!region_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
            fi
        fi
    done

    chmod 600 "$GF_PATHS_HOME/.aws/credentials"
fi

if [ ! -z "${GF_INSTALL_PLUGINS}" ]; then
  OLDIFS=$IFS
  IFS=','
  for plugin in ${GF_INSTALL_PLUGINS}; do
    IFS=$OLDIFS
    grafana-cli --pluginsDir "${GF_PATHS_PLUGINS}" plugins install ${plugin}
  done
fi

exec /usr/sbin/grafana-server                               \
  --homepath="$GF_PATHS_HOME"                               \
  --config="$GF_PATHS_CONFIG"                               \
  cfg:default.log.mode="console"                            \
  cfg:default.paths.data="$GF_PATHS_DATA"                   \
  cfg:default.paths.logs="$GF_PATHS_LOGS"                   \
  cfg:default.paths.plugins="$GF_PATHS_PLUGINS"             \
  cfg:default.paths.provisioning="$GF_PATHS_PROVISIONING"   \
  "$@"
