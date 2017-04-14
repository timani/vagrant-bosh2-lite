#!/usr/bin/env bash

set -ex

WORK_PATH=$(pwd)

apt-get install sudo git -y > /dev/null

curl -fS https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-2.0.1-linux-amd64 -o bosh
sudo chmod +x bosh
sudo mv bosh /usr/local/bin/
bosh --version


# 3. Install Director

# clone bosh deployment repo
git clone https://github.com/cloudfoundry/bosh-deployment || true

mkdir -p deployments/vbox
cd ./deployments/vbox

bosh create-env "${WORK_PATH}"/bosh-deployment/bosh.yml \
  --state ./state.json \
  -o "${WORK_PATH}"/bosh-deployment/virtualbox/cpi.yml \
  -o "${WORK_PATH}"/bosh-deployment/virtualbox/outbound-network.yml \
  -o "${WORK_PATH}"/bosh-deployment/bosh-lite.yml \
  -o "${WORK_PATH}"/bosh-deployment/bosh-lite-runc.yml \
  -o "${WORK_PATH}"/bosh-deployment/jumpbox-user.yml \
  --vars-store ./creds.yml \
  -v director_name="Bosh Lite Director" \
  -v internal_ip=192.168.50.6 \
  -v internal_gw=192.168.50.1 \
  -v internal_cidr=192.168.50.0/24 \
  -v outbound_network_name=NatNetwork


# 4. Alias and log into the Director

# setup Alias as vbox
bosh -e 192.168.50.6 --ca-cert <(bosh int ./creds.yml --path /director_ssl/ca) alias-env vbox  

# log into the Director
BOSH_CLIENT=admin  
BOSH_CLIENT_SECRET=$(bosh int ./creds.yml --path /admin_password)

export BOSH_CLIENT  
export BOSH_CLIENT_SECRET


# 5. Upload BOSH Lite stemcell 
bosh -e vbox upload-stemcell https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent

# running bosh status
bosh -e vbox env

