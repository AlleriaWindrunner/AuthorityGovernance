pragma solidity ^0.4.25;

import "./LibAddressSet.sol";
import "./SingletonVoter.sol";
import "./AclManager.sol";
import "./IAuthControl.sol";

contract WEAdmin{

    address private _admin;

    function initAdmin() internal{
        _admin = msg.sender;
    }

    modifier onlyAdmin(){
        require(msg.sender == _admin, "You are not admin");
        _;
    }
    

    event TransferAdminAuth(address indexed oldAdmin, address indexed newAdmin);

    function transferAdminAuth(address newAdminAddr) external onlyAdmin{
        address oldAdmin = _admin;
        _admin = newAdminAddr;
        emit TransferAdminAuth(oldAdmin, newAdminAddr);
    }
    
    function getAdmin() public view returns(address){
        return _admin;
    }

    function isAdmin() public view returns(bool){
        return  _admin == msg.sender;
    }
}