pragma solidity ^0.4.25;

import "./LibAddressSet.sol";
import "./SingletonVoter.sol";
import "./AclManager.sol";
import "./IAuthControl.sol";

contract GovManager is SingletonVoter{
    
    address[] private _accountsCache;
    uint16[] private _weightsCache;
    uint16 private _thresholdCache;    
    
    modifier validRequest(uint256 id) { 
        require(canCall(id), "WEGovernance: valid request failed.");
        _; 
        unregister(id);
    }
    
    modifier onlyGovs(){
        require(inGovs(), "you are not governors");
        _;
    }

    event InitWeightData(address[] accounts, uint16[] weights, uint16 threshold);
    function initWeightData(address[] accounts, uint16[] weights, uint16 threshold) internal{
        _voteWeight.setBoardWeight(accounts, weights, threshold);
        _accountsCache = accounts;
        _weightsCache = weights;
        _thresholdCache = threshold;
        emit InitWeightData(accounts, weights, threshold);
    }

    function getGovs() public view returns(address[], uint16[], uint16){
        return (_accountsCache, _weightsCache, _thresholdCache);
    }

    //--RESET THRESHOLD
    uint16 _pendingThreshold;
    uint8 constant private SET_THRESHOLD_TXTYPE = 1;
    event RequestSetThreshold(uint16 threshold);
    function requestSetThreshold(uint16 newThreshold) public onlyGovs preRegister(SET_THRESHOLD_TXTYPE){
        _pendingThreshold = newThreshold;
        emit RequestSetThreshold(newThreshold);
    }

    event ExecuteSetThreshold();
    function executeSetThreshold() public onlyGovs canExecute(SET_THRESHOLD_TXTYPE){
        _voteWeight.setThreshold(_pendingThreshold);
       _thresholdCache = _pendingThreshold;
       emit ExecuteSetThreshold();
    } 
    
    //---RESET GOVERNORS----
    uint _resetGovernorsReqId;
    address[] _pendingGovernors;
    uint16[] _pendingWeights;
    uint8 constant private RESET_GOVERNORS_TXTYPE = 2;
    event RequestResetGovernors(address[] governors, uint16[] weights);
    function requestResetGovernors(address[] governors, uint16[] weights) public onlyGovs preRegister(RESET_GOVERNORS_TXTYPE){
        _pendingGovernors = governors;
        _pendingWeights = weights;
        emit RequestResetGovernors(governors, weights);
    }

    event ExecuteResetGovernAccounts();
    function executeResetGovernAccounts() public onlyGovs canExecute(RESET_GOVERNORS_TXTYPE){
        _voteWeight = new WEVoteWeight();
        _voteWeight.setBoardWeight(_pendingGovernors, _pendingWeights, _thresholdCache);
        _accountsCache = _pendingGovernors;
        _weightsCache = _pendingWeights;
        emit ExecuteResetGovernAccounts();
    }
    

    //---ADD GOVERNOR---
    mapping(address=>uint) private _createGovernorAccountReqs;
    LibAddressSet.AddressSet private _pendingAccountsToAdd;
    event RequestAddGovernor(address account, uint reqId);
    function requestAddGovernor(address account) public onlyGovs {
        require(_createGovernorAccountReqs[account] == 0);
        (WEVoteRequest _, uint256 reqId) = super.register(11, address(0));    
        _createGovernorAccountReqs[account] = reqId;
        LibAddressSet.add(_pendingAccountsToAdd, account);
        emit RequestAddGovernor(account, reqId);
    }
    
    event DeleteAddGovernorReq(address account);
    function deleteAddGovernorReq(address account) public onlyGovs {
        uint reqId = _createGovernorAccountReqs[account];
        require(reqId > 0, "account not pending");
        require(unregister(reqId));
        LibAddressSet.remove(_pendingAccountsToAdd, account);
        delete _createGovernorAccountReqs[account];
        emit DeleteAddGovernorReq(account);
    }
    
    event ApproveAddGovernorReq(address account);
    function approveAddGovernorReq(address account) public onlyGovs {
        uint reqId = _createGovernorAccountReqs[account];
        require(reqId > 0, "account not pending");
        approve(reqId);
        emit ApproveAddGovernorReq(account);
    }   

    event ExecuteAddGovernorReq(address account);
    function executeAddGovernorReq(address account) public onlyGovs {
        uint reqId = _createGovernorAccountReqs[account];
        require(reqId > 0, "account not exist");      
        addGovernorByVote(reqId, account);
        LibAddressSet.remove(_pendingAccountsToAdd, account);
        delete _createGovernorAccountReqs[account];
        _accountsCache.push(account);
        _weightsCache.push(1);
        emit ExecuteAddGovernorReq(account);
    } 

    function addGovernorByVote(uint256 id, address account) private validRequest(id){
        _voteWeight.setWeight(account, 1);
    }

    function getGovernorsToAdd() public view returns(address[]){
        return LibAddressSet.getAll(_pendingAccountsToAdd);
    }

    function getAddGovRequest(address account) public view returns (uint256, address, uint16, address, uint16, uint8, uint8) {    
        uint reqId = _createGovernorAccountReqs[account];
        require(reqId > 0, "account not exist");      
        return super.getRequestInfo(reqId);
    }

    //---REMOVE GOVERNOR---
    mapping(address=>uint) private _removeGovernorAccountReqs;
    LibAddressSet.AddressSet private _pendingAccountsToRemove;
    event RequestRemoveGovernor(address account);
    function requestRemoveGovernor(address account) public onlyGovs {
        require(_removeGovernorAccountReqs[account] == 0);
        (WEVoteRequest _, uint256 reqId) = super.register(12, address(0));    
        _removeGovernorAccountReqs[account] = reqId;
        LibAddressSet.add(_pendingAccountsToRemove, account);
        emit RequestRemoveGovernor(account);
    }
    
    event DeleteRemoveGovernorReq(address account);
    function deleteRemoveGovernorReq(address account) public onlyGovs {
        uint reqId = _removeGovernorAccountReqs[account];
        require(reqId > 0);
        require(unregister(reqId));
        LibAddressSet.remove(_pendingAccountsToRemove, account);
        delete _removeGovernorAccountReqs[account];
        emit DeleteRemoveGovernorReq(account);
    }
    
    event ApproveRemoveGovernorReq(address account);
    function approveRemoveGovernorReq(address account) public onlyGovs {
        uint reqId = _removeGovernorAccountReqs[account];
        require(reqId > 0);
        approve(reqId);
        emit ApproveRemoveGovernorReq(account);
    }   
    
    event ExecuteRemoveGovernorReq(address account);
    function executeRemoveGovernorReq(address account) public onlyGovs {
        uint reqId = _removeGovernorAccountReqs[account];
        require(reqId > 0);     
        removeGovernorByVote(reqId, account);
        LibAddressSet.remove(_pendingAccountsToRemove, account);
        _removeGovernorAccountReqs[account];
        for(uint i=0;i<_accountsCache.length;i++){
            if(_accountsCache[i] == account){
                _accountsCache[i] = _accountsCache[_accountsCache.length-1];
                _weightsCache[i] = _weightsCache[_weightsCache.length-1];
                _accountsCache.length--;
                _weightsCache.length--;
            }
        }
        
        emit ExecuteRemoveGovernorReq(account);
    } 

    function removeGovernorByVote(uint256 id, address account) private validRequest(id){
        _voteWeight.setWeight(account, 0);
    }

    function getGovernorsToRemove() public view returns(address[]){
        return LibAddressSet.getAll(_pendingAccountsToRemove);
    }

    function getRemoveGovRequest(address account) public view returns (uint256, address, uint16, address, uint16, uint8, uint8) {    
        uint reqId = _removeGovernorAccountReqs[account];
        require(reqId > 0, "account not exist");      
        return super.getRequestInfo(reqId);
    }

    function inGovs() public view returns(bool){
        (uint16 weight, uint16 _) = _voteWeight.getWeight(msg.sender);
        return weight > 0;
    }
}