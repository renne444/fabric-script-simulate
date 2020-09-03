#!/bin/bash

export FABRIC_CFG_PATH=$PWD

function generateOrg3() {
    cryptogen generate --config=org3-crypto.yaml --output="../organizations"
}

function generateOrg3Definition() {
    #configtxgen -printOrg Org3MSP
    configtxgen -printOrg Org3MSP > ../organizations/peerOrganizations/org3.rennec.com/org3.json
}

function Org3Up() {
    docker-compose -f docker/docker-compose-org3.yaml up
}

generateOrg3
generateOrg3Definition
Org3Up

