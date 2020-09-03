#!/bin/bash

CHANNEL_NAME="channel"
DELAY="3"
TIMEOUT="10"
VERBOSE="false"

. ./envVar.sh
export FABRIC_CFG_PATH=$PWD/../../config

function fetchChannelConfig() {
  ORG=$1
  CHANNEL=$2
  OUTPUT=$3

  setOrdererGlobals
  setGlobals $ORG


  peer channel fetch config config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.rennec.com -c $CHANNEL --tls --cafile $ORDERER_CA
  configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >"${OUTPUT}"
  # configtxlator proto_decode --input config_block.pb --type common.Block >"${OUTPUT}"

}

function createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config >original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config >modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original original_config.pb --updated modified_config.pb >config_update.pb
  configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
  configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >"${OUTPUT}"

}

function signConfigtxAsPeerOrg() {
    PEERORG=$1
    TX=$2
    setGlobals $PEERORG
    peer channel signconfigtx -f "${TX}"
}

fetchChannelConfig 1 ${CHANNEL_NAME} config.json

jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json ./../organizations/peerOrganizations/org3.rennec.com/org3.json > modified_config.json
createConfigUpdate ${CHANNEL_NAME} config.json modified_config.json org3_update_in_envelope.pb

signConfigtxAsPeerOrg 1 org3_update_in_envelope.pb

setGlobals 2
peer channel update -f org3_update_in_envelope.pb -c ${CHANNEL_NAME} -o localhost:7050 --ordererTLSHostnameOverride orderer.rennec.com --tls --cafile ${ORDERER_CA}

