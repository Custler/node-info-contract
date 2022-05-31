#!/usr/bin/env bash

LNI_giver="0:c82cdbe63dbe05841af073d2d5f1299ee2f89430acfaa4048748b24841df167f"
LNI_seed="estate indicate weekend embark witness grief loyal voice key achieve wreck quiz"
NANO_AMOUNT=2000000000
BOUNCE="false"
Contract_Name="LastNodeInfo"

INIT_FILE="init_data.json"
DATA_FILE="update_data.json"

everdev sol compile ${Contract_Name}.sol

Code="${Contract_Name}.tvc"
ABI="${Contract_Name}.abi.json"

KEYS_FILE="${Contract_Name}.keys.json"
ADDR_FILE="${Contract_Name}.addr"

Calc_Addr="$(tonos-cli -j genaddr $Code --abi $ABI --setkey $KEYS_FILE --wc 0|jq -r '.raw_address' | tee "${ADDR_FILE}")"
echo "Calculated addr: $Calc_Addr"

tonos-cli call $LNI_giver sendTransaction \
"{\"dest\":\"${Calc_Addr}\",\"value\":${NANO_AMOUNT},\"bounce\":$BOUNCE,\"flags\":3,\"payload\":\"\"}" \
--abi SafeMultisigWallet.abi.json --sign "$LNI_seed"

#### Address ready to deploy

# Prepare init data
cat <<_ENDCNT_ > $INIT_FILE
{
  "initial_node_info": {
    "NodeVersion": "000050015",
    "PrevNodeVersion": "000050013",
    "LastCommit": "0xc7b2a7af27063cdd0414944a8c34ceb63c7f9dba",
    "PrevCommit": "0xcc96e3938763e640cca86c62a4e66167581ec4f3",
    "SupportedBlock": 27,
    "PrevSupportedBlock": 26,
    "UpdateByCron": true,
    "UpdateStartTime": 0,
    "UpdateDuration": 0,
    "MinCLIversion": "000026012",
    "DisableOldNodeValidate": false
  },
  "code_deploy_time": "xx",
  "info_deploy_time": "xx",
  "initial_ABI": "xxx"
}

_ENDCNT_

jq "del(.initial_ABI, .code_deploy_time) | .[\"new_node_info\"] = .initial_node_info | .[\"new_info_time\"] = .info_deploy_time | del (.initial_node_info, .info_deploy_time)" "${INIT_FILE}" > "${DATA_FILE}"

code_deploy_time="$(date +%s)"
info_deploy_time="$(date +%s)"
7za a -m0=ppmd ${Contract_Name}.abi.7z ${Contract_Name}.abi.json && xxd -ps ${Contract_Name}.abi.7z|tr -d '\n' > ${Contract_Name}.abi.hex
initial_ABI="$(cat ${Contract_Name}.abi.hex)"

cat ${INIT_FILE} |jq ".code_deploy_time = ${code_deploy_time} | .info_deploy_time = ${info_deploy_time} | .initial_ABI = \"${initial_ABI}\"" > ${INIT_FILE}.tmp
mv -f ${INIT_FILE}.tmp ${INIT_FILE}

#Deploy contract
tonos-cli deploy --wc 0 --abi ${ABI} --sign ${KEYS_FILE} ${Code} ${INIT_FILE}


exit 0

####################
## Examples:

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
