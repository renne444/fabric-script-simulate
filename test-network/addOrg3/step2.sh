#!/bin/bash

CHANNEL_NAME="channel"
DELAY="3"
TIMEOUT="10"
VERBOSE="false"

. ./envVar.sh
export FABRIC_CFG_PATH=$PWD/../../config

function joinChannel() {
  ORG=$1
  setGlobals $ORG
  peer channel join -b $CHANNEL_NAME.block
}

function fetchGenesisBlock() {
  setGlobals 3
  peer channel fetch 0 $CHANNEL_NAME.block -o localhost:7050 --ordererTLSHostnameOverride orderer.rennec.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
}

fetchGenesisBlock
joinChannel 3
