#!/bin/bash
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

function createOrgs() {

    cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="organizations"
    cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output="organizations"
    cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"

}

function createConsortium() {
  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock ./system-genesis-block/genesis.block
}

function networkUp() {

  createOrgs
  createConsortium
  docker-compose -f docker/docker-compose-test-net.yaml up

}

networkUp
