#!/bin/bash

rm channel.block config_block.pb config.json config_update.json config_update.pb config_update_in_envelope.json modified_config.json modified_config.pb org3_update_in_envelope.pb original_config.pb
docker-compose -f docker/docker-compose-org3.yaml down --volumes --remove-orphans

