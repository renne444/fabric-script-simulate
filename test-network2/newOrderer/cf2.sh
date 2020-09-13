#!/bin/bash
export CHANNEL_NAME=system-channel

. ./envVar.sh

function createExtraOrg(){
    cryptogen generate --config=./crypto-config-orderer-extra.yaml --output="organizations"
}
function createExtraOrgConfigInfo() {
  export FABRIC_CFG_PATH=${PWD}
  configtxgen -printOrg ExtraOrdererOrg > blockInfo/ExtraOrdererOrg.json
}

function fetchChannelConfig() {
  export FABRIC_CFG_PATH=${PWD}/../../config
  CHANNEL=$1
  OUTPUT=$2

  setOrdererGlobals

  peer channel fetch config blockInfo/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.rennec.com -c $CHANNEL --tls --cafile $ORDERER_CA
  configtxlator proto_decode --input blockInfo/config_block.pb --type common.Block | jq .data.data[0].payload.data.config >"${OUTPUT}"

}

function createConfigUpdate() {
  CHANNEL=$1
  ORIGINAL=$2
  MODIFIED=$3
  OUTPUT=$4

  configtxlator proto_encode --input "${ORIGINAL}" --type common.Config >blockInfo/original_config.pb
  configtxlator proto_encode --input "${MODIFIED}" --type common.Config >blockInfo/modified_config.pb
  configtxlator compute_update --channel_id "${CHANNEL}" --original blockInfo/original_config.pb --updated blockInfo/modified_config.pb >blockInfo/config_update.pb
  configtxlator proto_decode --input blockInfo/config_update.pb --type common.ConfigUpdate >blockInfo/config_update.json
  echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL'", "type":2}},"data":{"config_update":'$(cat blockInfo/config_update.json)'}}}' | jq . >blockInfo/config_update_in_envelope.json
  configtxlator proto_encode --input blockInfo/config_update_in_envelope.json --type common.Envelope >"${OUTPUT}"

}

createExtraOrg
createExtraOrgConfigInfo

fetchChannelConfig ${CHANNEL_NAME} blockInfo/config.json

createConfigUpdate ${CHANNEL_NAME} blockInfo/config.json blockInfo/modified_config.json blockInfo/org3_update_in_envelope.pb


