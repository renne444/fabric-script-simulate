#!/bin/bash
CHANNEL_NAME=channel
CC_SRC_PATH="./asset-transfer-basic/chaincode-go"
CC_RUNTIME_LANGUAGE=golang
CC_NAME="basic"
CC_VERSION=1.0
export FABRIC_CFG_PATH=${PWD}/../config

. ./envVar.sh
packageCC() {
    ORG=$1
    setGlobals $ORG
    peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION}
}

installCC() {
    ORG=$1
    setGlobals $ORG
    peer lifecycle chaincode install ${CC_NAME}.tar.gz
}

queryInstalled() {
    ORG=$1
    setGlobals $ORG
    peer lifecycle chaincode queryinstalled >& queryResult.txt
    PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" queryResult.txt)
    cat queryResult.txt
    echo "$PACKAGE_ID"
    
    rm queryResult.txt
}

CC_SEQUENCE=1

approveForMyOrg() {
    ORG=$1
    setGlobals $ORG
    peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.rennec.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id "${PACKAGE_ID}" --sequence ${CC_SEQUENCE}

}

checkCommitReadiness() {
	ORG=$1
	setGlobals $ORG
  peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --output json
}

commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.rennec.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE}

}

queryCommited() {
  ORG=$1
	setGlobals $ORG
  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME}
}

CC_INIT_FCN=initLedger

chaincodeInvokeInit() {
  parsePeerConnectionParameters $@
  fcn_call='{"function":"initLedger","Args":[]}'
  echo "invoke function call:${fcn_call}"

  peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.rennec.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS -c $"$fcn_call"
}

chaincodeQuery() {
	ORG=$1
	setGlobals $ORG
	fcn_call='{"Args":["getAllAssets"]}'
  #peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} $"$fcn_call"
  peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["getAllAssets"]}'
}


#packageCC 1

#installCC 1
#installCC 2

#queryInstalled 1

#approveForMyOrg 1
#checkCommitReadiness 1
#checkCommitReadiness 2

#approveForMyOrg 2
#checkCommitReadiness 1
#checkCommitReadiness 2

#commitChaincodeDefinition 1 2

#queryCommited 1
#queryCommited 2

# chaincodeInvokeInit 1 2
chaincodeQuery 1