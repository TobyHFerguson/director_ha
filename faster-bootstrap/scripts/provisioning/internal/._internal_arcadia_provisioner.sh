#!/usr/bin/env bash
#
# (c) Copyright 2017 Cloudera, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# For this script to work properly, you need to supply a URL to a parcel file,
# e.g. http://archive-primary.cloudera.com/cdh5/parcels/5.7.0/CDH-5.7.0-1.cdh5.7.0.p0.45-el7.parcel

# You can do this one of two ways:
# 1. Set a ARCADIA_PARCEL_URL environment variable.
# 2. Supply an argument that is a ARCADIA_PARCEL_URL.

# This script will have to be re-run for each parcel you want to cache on the
# image that you are building.

if [ -z "${ARCADIA_ZIP_URL+set}" ]
then
  if [ "$#" -ne 1 ]
  then
    echo "Usage: $0 <parcel-url>"
    echo ""
    echo "Alternatively, set the environment variable ARCADIA_ZIP_URL prior to"
    echo "running this script."
    echo "Silently exiting without setting up Arcadia parcel"
    exit 0
  else
    ARCADIA_ZIP_URL=$1
  fi
fi

sudo useradd -r cloudera-scm
sudo mkdir -p /opt/cloudera/parcels /opt/cloudera/parcel-repo /opt/cloudera/parcel-cache /opt/cloudera/csd

ZIP_NAME="${ARCADIA_ZIP_URL##*/}"

echo "Downloading ZIP from $ARCADIA_ZIP_URL"
sudo -E /usr/bin/curl -s -S "${ARCADIA_ZIP_URL}" -o "/tmp/${ZIP_NAME}"
sudo unzip -j -o /tmp/${ZIP_NAME} "ARCADIAENTERPRISE*/ARCADIAENTERPRISE*.jar" -d /opt/cloudera/csd

echo "Extracting parcel from ZIP"
sudo unzip -j -o /tmp/${ZIP_NAME} "ARCADIAENTERPRISE*/ARCADIAENTERPRISE*.parcel" -d /opt/cloudera/parcel-repo
PARCEL_LOC=(/opt/cloudera/parcel-repo/ARCADIAENTERPRISE*.parcel)
PARCEL_NAME="${PARCEL_LOC##*/}"
PARCEL_DIR="${PARCEL_NAME%-el*}"
sha1sum /opt/cloudera/parcel-repo/${PARCEL_NAME} | awk '{print $1}' | sudo tee  /opt/cloudera/parcel-repo/${PARCEL_NAME}.sha

sudo ln /opt/cloudera/parcel-repo/${PARCEL_NAME} /opt/cloudera/parcel-cache/${PARCEL_NAME}
sudo chown -R cloudera-scm:cloudera-scm /opt/cloudera

if [ "${PREEXTRACT_PARCEL}" = true ]
then
  echo "Preextracting parcels..."
  sudo tar zxf "/opt/cloudera/parcel-repo/${PARCEL_NAME}" -C "/opt/cloudera/parcels"
  sudo ln -s ${PARCEL_DIR} /opt/cloudera/parcels/ARCADIAENTERPRISE
  sudo touch /opt/cloudera/parcels/ARCADIAENTERPRISE/.dont_delete
  echo "Done"
fi

echo "Sync Linux volumes with EBS."
sudo sync
sleep 5
