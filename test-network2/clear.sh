rm -rf system-genesis-block organizations/ordererOrganizations organizations/peerOrganizations
docker-compose -f docker/docker-compose-test-net.yaml down --volumes --remove-orphans
