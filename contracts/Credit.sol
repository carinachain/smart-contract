// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "./CRNAdmin.sol";

contract Credit is ERC20, ERC20Pausable, CRNAdmin {
    string public constant CONTRACT = "CARINA_CREDIT_V1.0.0";
    ContractType public constant thisContractType = ContractType.CREDIT;
    
    uint8 private constant _decimals = 0;
    uint256 public distributeLimit = 500000;

    mapping(address => uint256) private _lastBalanceUpdateTime;

    event Distributed(address indexed senderAddress, address indexed userAddress, uint256 amount);
    event Deducted(address indexed senderAddress, address indexed userAddress, uint256 amount);
    event DistributeLimitChanged(uint256 previousValue, uint256 newValue);

    constructor (address adminControlAddress) ERC20("Credit_in_CRNChain", "CRD"){
        adminControl = adminControlAddress;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function getAddressBalanceTimeStamp(
        address targetAddress
    ) external view returns (uint256, uint256) {
        return (balanceOf(targetAddress), _lastBalanceUpdateTime[targetAddress]);
    }

    function distribute(
        address userAddress, 
        uint256 amount
    ) external onlyAdmin returns(bool){
        require(amount > 0 && amount <= distributeLimit, "Invalid amount");
        _mint(userAddress, amount);
        emit Distributed(msg.sender, userAddress, amount);
        return true;
    }

    function deduct(
        address userAddress, 
        uint256 amount
    ) external onlyAdmin returns(bool){
        require(amount > 0, "Invalid amount");
        _burn(userAddress, amount);
        emit Deducted(msg.sender, userAddress, amount);
        return true;
    }

    function pTransfer(
        address from, 
        address to, 
        uint256 amount
    ) external onlyAdmin returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    function _update(
        address from, 
        address to, 
        uint256 value
    ) internal override(ERC20, ERC20Pausable) onlyAdmin {
        super._update(from, to, value);

        if(from != address(0)){
            _lastBalanceUpdateTime[from] = block.timestamp;
        }
        if(to != address(0)){
            _lastBalanceUpdateTime[to] = block.timestamp;
        }
    }
    
    function changePauseStatus(
        bool newValue
    ) external onlyAdmin returns(bool) {
        if(newValue){
            _pause();
        } else {
            _unpause();
        }
        return true;
    }

    function setDistributeLimit(
        uint256 newValue
    ) external onlyAdmin returns(bool){
        uint256 previousValue = distributeLimit;
        require(newValue != previousValue, "newValue is same as now");
        distributeLimit = newValue;
        emit DistributeLimitChanged(previousValue, newValue);
        return true;
    }

    function updateAdmin() external {
        _updateAdmin(thisContractType);
    }

}