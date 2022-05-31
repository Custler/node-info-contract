#!/usr/bin/env bash

Contract_Name="LastNodeInfo"

everdev sol compile ${Contract_Name}.sol

Code="${Contract_Name}.tvc"
ABI="${Contract_Name}.abi.json"

KEYS_FILE="${Contract_Name}.keys.json"
ADDR_FILE="${Contract_Name}.addr"

# Prepare update data
UPDATE_FILE="update_code.json"
DATA_FILE="update_data.json"

cat <<_ENDCNT_ > $UPDATE_FILE
{
  "newcode": "xxx",
  "new_code_time": "xx",
  "new_ABI": "xxx"
}

_ENDCNT_

newcode="$(tonos-cli -j decode stateinit --tvc ${Contract_Name}.tvc | jq -r '.code')"

new_code_time="$(date +%s)"
7za a -m0=ppmd ${Contract_Name}.abi.7z ${ABI} && xxd -ps ${Contract_Name}.abi.7z|tr -d '\n' > ${Contract_Name}.abi.hex
new_ABI="$(cat ${Contract_Name}.abi.hex)"

cat "${UPDATE_FILE}" | jq ".newcode = \"${newcode}\" | .new_code_time = ${new_code_time} | .new_ABI = \"${new_ABI}\"" > "${UPDATE_FILE}.tmp"
mv -f "${UPDATE_FILE}.tmp" "${UPDATE_FILE}"

# Update contract code
tonos-cli call --abi ${ABI} --sign ${KEYS_FILE} $(cat ${ADDR_FILE}) updateContractCode ${UPDATE_FILE}
# "{\"newcode\": \"$NewCode\", \"new_ABI\": \"$NewABI\"}"

# restore node info after update code
new_info_time="$(date +%s)"
cat "${DATA_FILE}" | jq ".new_info_time = ${new_info_time}" > "${DATA_FILE}.tmp"
mv -f "${DATA_FILE}.tmp" "${DATA_FILE}"
tonos-cli call --abi ${ABI} --sign ${KEYS_FILE} $(cat ${ADDR_FILE}) change_node_info ${DATA_FILE}

exit 0

    function updateContractCode(TvmCell newcode,  uint32 new_code_time, string new_ABI) external checkPubkeyAndAccept{

{
			"name": "updateContractCode",
			"inputs": [
				{"name":"newcode","type":"cell"},
				{"name":"new_code_time","type":"uint32"},
				{"name":"new_ABI","type":"string"}
			],
			"outputs": [
			]
		},

tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) getALLinfo {}

tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) getLastNodeInfo {}
tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) node_info {}
tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) code_ver {}
tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) code_updated_time {}
tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) info_updated_time {}
tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) ABI {}
tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) ABI {}|jq -r '.ABI'|xxd -r -p > lnm.7z
tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) getABI {}
tonos-cli -j run --abi ${Contract_Name}.abi.json $(cat ${Contract_Name}.addr) getABI {}|jq -r '.value0'|xxd -r -p > lnm.7z
