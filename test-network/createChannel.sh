#!/bin/zsh

CHANNEL_NAME=channel

export FABRIC_CFG_PATH=${PWD}/configtx
. ./envVar.sh

createChannelTx() {

    configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx -channelID ${CHANNEL_NAME}

}

createAnchorPeerTx() {

    for orgmsp in Org1MSP Org2MSP; do
	
	configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/${orgmsp}anchors.tx -channelID $CHANNEL_NAME -asOrg $orgmsp
    done	    
}

createChannel() {
    export FABRIC_CFG_PATH=${PWD}/../config
    setGlobals 1
    peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.rennec.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block --tls --cafile $ORDERER_CA 
}

joinChannel() {
    export FABRIC_CFG_PATH=${PWD}/../config
    ORG=$1
    setGlobals $ORG
    peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block

}

updateAnchorPeers() {
    export FABRIC_CFG_PATH=${PWD}/../config
    ORG=$1
    setGlobals $ORG
    peer channel update -o localhost:7050 --ordererTLSHostnameOverride orderer.rennec.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $ORDERER_CA

}

createChannelTx
createAnchorPeerTx
createChannel
joinChannel 1
joinChannel 2

updateAnchorPeers 1
updateAnchorPeers 2

