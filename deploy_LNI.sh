#!/usr/bin/env bash
set -eE

# LNI_giver="0:c82cdbe63dbe05841af073d2d5f1299ee2f89430acfaa4048748b24841df167f"
# LNI_seed="estate indicate weekend embark witness grief loyal voice key achieve wreck quiz"
NANO_AMOUNT=2000000000
BOUNCE="false"
Contract_Name="LastNodeInfo"

INIT_FILE="init_data.json"
DATA_FILE="update_data.json"

# everdev sol compile ${Contract_Name}.sol

Code="${Contract_Name}.tvc"
ABI="${Contract_Name}.abi.json"

KEYS_FILE="${Contract_Name}.keys.json"
ADDR_FILE="${Contract_Name}.addr"

if [[ ! -s $Code ]] || [[ ! -s $ABI ]] || [[ ! -s $KEYS_FILE ]];then
  echo "###-ERROR(line $LINENO): Check tvc, abi and keys files exist!"
  exit 1
fi

Calc_Addr="$(tonos-cli -j genaddr $Code --abi $ABI --setkey $KEYS_FILE --wc 0|jq -r '.raw_address' | tee "${ADDR_FILE}")"
echo
echo "Calculated addr: $Calc_Addr"
echo "        Network: $(tonos-cli -j config|jq -r '.url')"
echo

# Prepare init data
cat <<_ENDCNT_ > $INIT_FILE
{
  "initial_node_info": {
    "NodeVersion": "000050015",
    "PrevNodeVersion": "000050013",
    "LastCommit": "0xa0bc069b0459b50e4be7ed7d07c0aef0380ec2f7",
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

echo "Info for deploy:"
cat $INIT_FILE |jq ''

#### Address ready to deploy
read -p "### CHECK INFO TWICE!!! Is this a right address?  (y/n)? " </dev/tty answer
case ${answer:0:1} in
    y|Y )
        echo "Deploing..."
    ;;
    * )
        echo "Cancelled."
        exit 1
    ;;
esac

#Deploy contract
tonos-cli deploy --wc 0 --abi ${ABI} --sign ${KEYS_FILE} ${Code} ${INIT_FILE}


exit 0

####################s
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
