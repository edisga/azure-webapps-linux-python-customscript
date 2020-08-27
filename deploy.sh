#!/bin/bash

# Review and change the Python version 
# Check in Kudu Python version list in /opt/python/
# export PYTHON3="/opt/python/3.6.10/bin/python3.6"

# ----------------------
# KUDU Deployment Script
# Version: {Version}
# ----------------------

# Helpers
# -------

exitWithMessageOnError () {
  if [ ! $? -eq 0 ]; then
    echo "An error has occurred during web site deployment."
    echo $1
    exit 1
  fi
}

# Setup
# -----

SCRIPT_DIR="${BASH_SOURCE[0]%\\*}"
SCRIPT_DIR="${SCRIPT_DIR%/*}"
ARTIFACTS=$SCRIPT_DIR/../artifacts
KUDU_SYNC_CMD=${KUDU_SYNC_CMD//\"}

if [[ ! -n "$DEPLOYMENT_SOURCE" ]]; then
  DEPLOYMENT_SOURCE=$SCRIPT_DIR
fi

if [[ ! -n "$NEXT_MANIFEST_PATH" ]]; then
  NEXT_MANIFEST_PATH=$ARTIFACTS/manifest

  if [[ ! -n "$PREVIOUS_MANIFEST_PATH" ]]; then
    PREVIOUS_MANIFEST_PATH=$NEXT_MANIFEST_PATH
  fi
fi

if [[ ! -n "$DEPLOYMENT_TARGET" ]]; then
  DEPLOYMENT_TARGET=$ARTIFACTS/wwwroot
else
  KUDU_SERVICE=true
fi

if [[ ! -n "$KUDU_SYNC_CMD" ]]; then
  # Install kudu sync
  echo Installing Kudu Sync
  npm install kudusync -g --silent
  exitWithMessageOnError "npm failed"

  if [[ ! -n "$KUDU_SERVICE" ]]; then
    # In case we are running locally this is the correct location of kuduSync
    KUDU_SYNC_CMD=kuduSync
  else
    # In case we are running on kudu service this is the correct location of kuduSync
    KUDU_SYNC_CMD=$APPDATA/npm/node_modules/kuduSync/bin/kuduSync
  fi
fi


echo Python deployment.

# 1. KuduSync


if [[ "$IN_PLACE_DEPLOYMENT" -ne "1" ]]; then
  "$KUDU_SYNC_CMD" -v 50 -f "$DEPLOYMENT_SOURCE" -t "$DEPLOYMENT_TARGET" -n "$NEXT_MANIFEST_PATH" -p "$PREVIOUS_MANIFEST_PATH" -i ".git;.hg;.deployment;deploy.sh"
  exitWithMessageOnError "Kudu Sync failed"
fi


#2. Install any dependencies

export ANTENV="antenv"
export PYTHON3="/opt/python/3.6.10/bin/python3.6"

if [ "$WEBSITE_PYTHON_VERSION" = "3.6" ]; then
    export ANTENV="antenv3.6"
    export PYTHON3="/opt/python/3.6.10/bin/python3.6"
fi

echo "$DEPLOYMENT_SOURCE"
echo "$DEPLOYMENT_TARGET"


if [ -e "$DEPLOYMENT_TARGET/requirements.txt" ]; then
  echo "Found requirements.txt"
  echo "Python Virtual Environment: $ANTENV"
  echo "Python Version: $PYTHON3"

  cd "$DEPLOYMENT_TARGET"

  #2a. Setup virtual Environment
  echo "Create virtual environment"
  $PYTHON3 -m venv $ANTENV --copies

  #2b. Activate virtual environment
  echo "Activate virtual environment"
  source $ANTENV/bin/activate

  #2c. Install dependencies
  pip install -r requirements.txt

  echo "pip install finished"
fi