pragma solidity ^0.4.25;

import "./LibAddressSet.sol";
import "./SingletonVoter.sol";
import "./AclManager.sol";
import "./IAuthControl.sol";
import "./GovManager.sol";
import "./Admin.sol";

contract AuthManager is Admin, GovManager, AclManager, IAuthControl{
    
    uint private _mode;

    /**
    * 1 - ADMIN
    * 2 - VOTE
    **/
    constructor(uint mode,address[] accounts, uint16[] weights, uint16 threshold) public{
        _mode = mode;
        if(_mode == 1){
            super.initAdmin();
        }
        if(_mode == 2){
            super.initWeightData(accounts, weights, threshold);
        }
    }

    function opMode() public view returns(uint){
        return _mode;
    } 

    modifier canCallFunc(address contractAddr, bytes4 funcSig, address caller) {
        require(canCallFunction(contractAddr, funcSig, caller), "Forbidden");
        _;
    }

    function approveSingle(uint8 txType) public onlyGovs {
        super.approveSingleImpl(txType);
    }

    function deleteSingle(uint8 txType) public onlyGovs{
        super.deleteSingleImpl(txType);
    }

    //By admin
    function createGroup(string group, uint8 mode) public onlyAdmin{
        super.createGroupImpl(group, mode);
    }
    
    function addAccountToGroup(address account, string group) public  onlyAdmin{
        super.addAccountToGroupImpl(account, group);
    }
    
    function addFunctionToGroup(address contractAddr, string func, string group) public  onlyAdmin{
        super.addFunctionToGroupImpl(contractAddr, func, group);
    }
    
    function removeAccountFromGroup(address account, string group) public onlyAdmin{
        super.removeAccountFromGroupImpl(account, group);
    }
    
    function removeFunctionFromGroup(address contractAddr, string func, string group) public onlyAdmin{
        super.removeFunctionFromGroupImpl(contractAddr, func, group);
    }
    
    //By Vote
    uint8 constant private CREATE_GROUP = 3;
    string private _createGroupGroup;
    uint8 private _createGroupMode;
    event RequestCreateGroup(string group, uint8 mode);
    function requestCreateGroup(string group, uint8 mode) public onlyGovs preRegister(CREATE_GROUP){
        _createGroupGroup = group;
        _createGroupMode = mode;
        emit RequestCreateGroup(group, mode);
    }
    
    function viewCreateGroup() public onlyGovs view returns(string, uint8){
        return (_createGroupGroup, _createGroupMode);
    }

    function executeCreateGroup() public onlyGovs canExecute(CREATE_GROUP) {
        super.createGroupImpl(_createGroupGroup, _createGroupMode);
    }

    uint8 constant private ADD_ACCOUNT_TO_GROUP = 4;
    address private _addAccountToGroupAccount;
    string private _addAccountToGroupGroup;
    event RequestAddAccountToGroup(address account, string group);
    function requestAddAccountToGroup(address account, string group) public onlyGovs preRegister(ADD_ACCOUNT_TO_GROUP){
        _addAccountToGroupAccount = account;
        _addAccountToGroupGroup = group;
        emit RequestAddAccountToGroup(account, group);
    }

    function viewAddAccountToGroup() public view onlyGovs returns(address, string){
        return (_addAccountToGroupAccount,_addAccountToGroupGroup);
    }

    function executeAddAccountToGroup() public onlyGovs canExecute(ADD_ACCOUNT_TO_GROUP){
        super.addAccountToGroupImpl(_addAccountToGroupAccount, _addAccountToGroupGroup);
    }

    uint8 constant private ADD_FUNCTION_TO_GROUP = 5;
    address private _addFunctionToGroupContract;
    string private _addFunctionToGroupFunc;
    string private _addFunctionToGroupGroup;
    event RequestAddFunctionToGroup(address contractAddr, string func, string group);
    function requestAddFunctionToGroup(address contractAddr, string func, string group) public onlyGovs preRegister(ADD_FUNCTION_TO_GROUP){
        _addFunctionToGroupContract = contractAddr;
        _addFunctionToGroupFunc = func;
        _addFunctionToGroupGroup = group;
        emit RequestAddFunctionToGroup(contractAddr, func, group);
    }

    function viewAddFunctionToGroup() public view onlyGovs returns(address, string, string){
        return (_addFunctionToGroupContract,_addFunctionToGroupFunc,_addFunctionToGroupGroup);
    }

    function executeAddFunctionToGroup() public onlyGovs canExecute(ADD_FUNCTION_TO_GROUP){
        super.addFunctionToGroupImpl(_addFunctionToGroupContract, _addFunctionToGroupFunc, _addFunctionToGroupGroup);
    }

    uint8 constant private REMOVE_ACCOUNT_FROM_GROUP = 6;
    address private _removeAccountFromGroupAccount;
    string private _removeAccountFromGroupGroup;
    event RequestRemoveAccountFromGroup(address account, string group);
    function requestRemoveAccountFromGroup(address account, string group) public onlyGovs preRegister(REMOVE_ACCOUNT_FROM_GROUP){
        _removeAccountFromGroupAccount = account;
        _removeAccountFromGroupGroup = group;
        emit RequestRemoveAccountFromGroup(account, group);
    }

    function viewRemoveAccountToGroup() public view onlyGovs returns(address, string){
        return (_removeAccountFromGroupAccount,_removeAccountFromGroupGroup);
    }

    function executeRemoveAccountFromGroup() public onlyGovs canExecute(REMOVE_ACCOUNT_FROM_GROUP){
        super.removeAccountFromGroupImpl(_removeAccountFromGroupAccount, _removeAccountFromGroupGroup);
    }

    uint8 constant private REMOVE_FUNCTION_FROM_GROUP = 7;
    address private _removeFunctionFromGroupContract;
    string private _removeFunctionFromGroupFunc;
    string private _removeFunctionFromGroupGroup;
    event RequestRemoveFunctionFromGroup(address contractAddr, string func, string group);
    function requestRemoveFunctionFromGroup(address contractAddr, string func, string group) public onlyGovs preRegister(REMOVE_FUNCTION_FROM_GROUP){
        _removeFunctionFromGroupContract = contractAddr;
        _removeFunctionFromGroupFunc = func;
        _removeFunctionFromGroupGroup = group;
        emit RequestRemoveFunctionFromGroup(contractAddr, func, group);
    }

    function viewRemoveFunctionToGroup() public view onlyGovs returns(address, string, string){
        return (_removeFunctionFromGroupContract,_removeFunctionFromGroupFunc,_removeFunctionFromGroupGroup);
    }

    function executeRemoveFunctionFromGroup() public onlyGovs canExecute(REMOVE_FUNCTION_FROM_GROUP){
        super.removeFunctionFromGroupImpl(_removeFunctionFromGroupContract, _removeFunctionFromGroupFunc, _removeFunctionFromGroupGroup);
    }

    
     function canCallFunction(address contractAddr, bytes4 sig, address caller) public view returns(bool){
        //Not configured for this function
        string groupName = _functionToGroups[contractAddr][sig];
        Group storage group = _groups[groupName];
        if(group.mode == 0) return true;
        //Take function mode
        uint8 mode = group.mode;
       
        //Where member in group
        bool memberInGroup = group.accList[caller];
        if(mode == WHITE) return memberInGroup;
        return !memberInGroup;
    } 
}


















