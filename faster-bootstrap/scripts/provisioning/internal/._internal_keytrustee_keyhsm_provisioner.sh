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

if [ -z "${KEYTRUSTEE_KEYHSM_URL+set}"  ]
then
  echo "Environment variable KEYTRUSTEE_KEYHSM_URL not set"
  echo "Silently exiting without setting up KeyTrustee KeyHSM"
  exit 0
fi

# Define service_control
#. /tmp/service_control.sh

sudo yum localinstall -y ${KEYTRUSTEE_KEYHSM_URL}

#service_control cloudera-keyhsm disable
exit 0
