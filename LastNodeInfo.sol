// (C) Sergey Tyurin (Custler) 2022-05-27 10:00:00

pragma ton-solidity >= 0.50.0;
pragma AbiHeader time;
pragma AbiHeader expire;

//==============================================================
// rust node compatibility info
struct NodeInfo {
    uint24  NodeVersion;            // 000050015 - means 0.50.15 - each number converto to xxx
    uint24  PrevNodeVersion;        // 05013
    uint180 LastCommit;             // c7b2a7af27063cdd0414944a8c34ceb63c7f9dba
    uint180 PrevCommit;             // cc96e3938763e640cca86c62a4e66167581ec4f3
    uint8   SupportedBlock;         // 27
    uint8   PrevSupportedBlock;     // 26
    bool    UpdateByCron;           // true - if allowed autoupdate by cron; false - if it is must be updated by hands
    uint32  UpdateStartTime;        // Time to start update  period (UNNIX time)
    uint32  UpdateDuration;         // time period for all network node for update. 
                                    //    For example, set it for 2 weeks, nodes will update during 2 weeks interval divided by 256. 
                                    //    Eeach node will update in time according to byte in middle of validator address.
                                    //    If set to 0, nodes will updates in one or two elections round
    uint24  MinCLIversion;          // min tonos-cli version for Custler's scripts
    bool    DisableOldNodeValidate;
}

contract CurrentNodeInfo {
    NodeInfo public node_info;          // Info structure
    uint8  public code_ver;             // Version of the contract
    uint32 public code_updated_time;    // UNIIX time
    uint32 public info_updated_time;    // UNIIX time
    string public ABI;                  /* Store the contract json ABI as 7z archive converted to hex string
                                           - pack:  
                                                7za a -m0=ppmd LastNodeInfo.abi.7z LastNodeInfo.abi.json
                                                xxd -ps LastNodeInfo.abi.7z|tr -d '\n' > LastNodeInfo.abi.hex
                                           - unpack:
                                                xxd -r -p LastNodeInfo.abi.hex > lnm.7z
                                                7za x lnm.7z
                                        */
    
    /*
    Exception codes:
        901 - code deploy time is early then the contract published time ))
        902 - node info deploy time is early code deploy time
        903 - new info update time less then current info updated time
        904 - new code update time less then current code updated time
    */

    // Modifier that allows public function to be called only by message signed with owner's pubkey.
    modifier checkPubkeyAndAccept {
	require(msg.pubkey() == tvm.pubkey(), 102);
	tvm.accept();
	_;
    }

    constructor(NodeInfo initial_node_info, uint32 code_deploy_time, uint32 info_deploy_time, string initial_ABI ) public {
        require(code_deploy_time > 1653553322, 901);
        require(info_deploy_time >= code_deploy_time, 902);
        require(tvm.pubkey() != 0, 101);
        require(msg.pubkey() == tvm.pubkey(), 102);
        tvm.accept();
        code_ver = 1;
        node_info = initial_node_info;
        ABI = initial_ABI;
        code_updated_time = code_deploy_time;
        info_updated_time = info_deploy_time;
    }

    function change_node_info(NodeInfo new_node_info, uint32 new_info_time) external checkPubkeyAndAccept{
        require(new_info_time > info_updated_time, 903);
        info_updated_time = new_info_time;
        node_info = new_node_info;
    }

    function getLastNodeInfo () external view returns (NodeInfo) {
            return node_info;
    } 
    function getABI () external view returns (string) {
            return ABI;
    } 

    function getALLinfo () external view returns (NodeInfo, uint8, uint32, uint32) {
            return (node_info, code_ver, code_updated_time, info_updated_time);
    } 

    // ###########################################################################
    function updateContractCode(TvmCell newcode,  uint32 new_code_time, string new_ABI) external checkPubkeyAndAccept{
        require(new_code_time > code_updated_time, 904);
	    tvm.setcode(newcode);
	    tvm.setCurrentCode(newcode);
        TvmCell stateVars = abi.encode(code_ver, new_ABI, new_code_time, info_updated_time);
        onCodeUpgrade(stateVars); 
    }

    function onCodeUpgrade(TvmCell stateVars) private {
        tvm.resetStorage();
        (uint8 version, string _new_ABI, uint32 _new_code_time, uint32 _info_updated_time) = abi.decode(stateVars, (uint8, string, uint32, uint32));
        code_ver = version + 1;
        code_updated_time = _new_code_time;
        info_updated_time = _info_updated_time;
        ABI = _new_ABI;
    }
}
