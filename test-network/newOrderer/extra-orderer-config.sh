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

function fetchBlock() {
  setOrdererGlobals
  peer channel fetch config blockInfo/config_block.pb -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.rennec.com --tls --cafile $ORDERER_CA
  configtxlator proto_decode --input blockInfo/config_block.pb --type common.Block | jq .data.data[0].payload.data.config > blockInfo/config.json
}

function generateConfigJson() {
jq -s '.[0] * {"channel_group":{"groups":{"Orderer":{"groups": {"ExtraOrdererOrg":.[1]}}}}}' ./blockInfo/config.json ./blockInfo/ExtraOrdererOrg.json > blockInfo/config1.json
jq -s '.[0] * {"channel_group":{"groups":{"Consortiums":{"groups":{"SampleConsortium":{"groups": {"ExtraOrdererOrgMSP":.[1]}}}}}}}' blockInfo/config1.json ./blockInfo/ExtraOrdererOrg.json > blockInfo/config2.json
cert=$(base64 ./organizations/ordererOrganizations/extra.com/orderers/orderer.extra.com/tls/server.crt | sed ':a;N;$!ba;s/\n//g')
cat ./blockInfo/config2.json | jq '.channel_group.groups.Orderer.values.ConsensusType.value.metadata.consenters += [{"client_tls_cert": "'$cert'", "host": "orderer.extra.com", "port": 8050, "server_tls_cert": "'$cert'"}] ' > blockInfo/modified_config.json
}

function generateConfigBlock() {
configtxlator proto_encode --input blockInfo/config.json --type common.Config --output blockInfo/config.pb
configtxlator proto_encode --input blockInfo/modified_config.json --type common.Config --output blockInfo/modified_config.pb
configtxlator compute_update --channel_id $CHANNEL_NAME --original blockInfo/config.pb --updated blockInfo/modified_config.pb --output blockInfo/newordorg.pb
configtxlator proto_decode --input blockInfo/newordorg.pb --type common.ConfigUpdate | jq . > blockInfo/newordorg.json


echo '{"payload":{"header":{"channel_header":{"channel_id":"'$(echo ${CHANNEL_NAME})'", "type":2}},"data":{"config_update":'$(cat blockInfo/newordorg.json)'}}}' | jq . > blockInfo/ordorg_update_in_envelope.json
configtxlator proto_encode --input blockInfo/ordorg_update_in_envelope.json --type common.Envelope --output blockInfo/ordorg_update_in_envelope.pb

}

function submitNewConfigBlock() {
  setOrdererGlobals
  peer channel update -f blockInfo/ordorg_update_in_envelope.pb -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.rennec.com --tls --cafile $ORDERER_CA
}

function fetchLatestConfigBlock() {
  peer channel fetch config ../system-genesis-block/latest.block -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.rennec.com --tls --cafile $ORDERER_CA
}
function dockerUp() {
  docker-compose -f docker-compose-new-orderer.yaml up
}

createExtraOrg
createExtraOrgConfigInfo

export FABRIC_CFG_PATH=${PWD}/../../config

fetchBlock

generateConfigJson
generateConfigBlock
submitNewConfigBlock

#fetchLatestConfigBlock
#dockerUp
