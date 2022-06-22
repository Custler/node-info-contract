#!/usr/bin/env bash

Contract_Name="LastNodeInfo"
DATA_FILE="update_data.json"
ABI="${Contract_Name}.abi.json"

# everdev sol compile ${Contract_Name}.sol

KEYS_FILE="${Contract_Name}.keys.json"
ADDR_FILE="${Contract_Name}.addr"

# restore node info after update code
new_info_time="$(date +%s)"
cat "${DATA_FILE}" | jq ".new_info_time = ${new_info_time}" > "${DATA_FILE}.tmp"
mv -f "${DATA_FILE}.tmp" "${DATA_FILE}"
tonos-cli call --abi ${ABI} --sign ${KEYS_FILE} $(cat ${ADDR_FILE}) change_node_info ${DATA_FILE}

exit 0
