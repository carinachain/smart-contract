// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "./ShareEnums.sol";

contract Point is ERC20, ERC20Pausable, Ownable {
    string public constant COPYRIGHT = "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV = "NebulaInfinity.com";

    ContractType public immutable thisContractType;
    
    uint8 private _decimals;
    address private _creator;
    bool private _transferSwitch;

    // 2024/10/12 add
    mapping(address => uint256) private _lastBalanceUpdateTime;

    event Distributed(address indexed senderAddress, address indexed userAddress, uint256 amount);
    event Deducted(address indexed senderAddress, address indexed userAddress, uint256 amount);
    event TransferSwitchChanged(bool indexed newValue);
    event CreatorChanged(address indexed previousCreator, address indexed newCreator);
    event PauseStatusChanged(address senderAddress, bool indexed newValue);

    modifier onlyCreator(address senderAddress) {
        require(senderAddress == _creator, "CreatorAddress only");
        _;
    }


    constructor (
        address creatorAddress_, 
        ContractType createContractType, 
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        if (creatorAddress_ == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        require(createContractType != ContractType.UNDEFINED, "Invalid ContractType");

        _creator = creatorAddress_;
        _decimals = decimals_;
        thisContractType = createContractType;

        // default transfer switch off only permit transfer through owner 
        _transferSwitch = false;
    }


    // get decimals
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // 2024/10/12 add function
    function getAddressBalanceTimeStamp(address targetAddress) external view returns (uint256, uint256) {
        return (balanceOf(targetAddress), _lastBalanceUpdateTime[targetAddress]);
    }

    // distribution
    function distribute(
        address senderAddress, 
        address userAddress, 
        uint256 amount
    ) external  onlyOwner {
        require(amount != 0, "Invalid amount");
        _mint(userAddress, amount);
        emit Distributed(senderAddress, userAddress, amount);
    }

    // deduction
    function deduct(
        address senderAddress, 
        address userAddress, 
        uint256 amount
    ) external onlyOwner{
        require(amount != 0, "Invalid amount");
        _burn(userAddress, amount);
        emit Deducted(senderAddress, userAddress, amount);
    }

    // only owner transfer
    function pTransfer(
        address from, 
        address to, 
        uint256 amount
    ) external onlyOwner returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    // get transfer switch's status
    function transferSwitchStatus() external view returns (bool) {
        return _transferSwitch;
    }

    // transfer switch setting
    function setTransferSwitch(bool newValue) external onlyOwner {
        require(newValue != _transferSwitch, "value is same as now");
        _transferSwitch = newValue;
        emit TransferSwitchChanged(newValue);
    }

    // 2024/10/12 update for _lastBalanceUpdataTime
    // switch off: only can transfer through owner; switch on: can transfer by user-self 
    function _update(
        address from, 
        address to, 
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        require(msg.sender == owner() || _transferSwitch, "No authorization to transfer");
        super._update(from, to, value);

        if(from != address(0)){
            _lastBalanceUpdateTime[from] = block.timestamp;
        }
        if(to != address(0)){
            _lastBalanceUpdateTime[to] = block.timestamp;
        }
    }

    // get creator address
    function creator() external view returns (address){
        return _creator;
    }
    
    // change creator
    function changeCreator(
        address senderAddress, 
        address newCreator
    ) external onlyOwner onlyCreator(senderAddress) {
        if (newCreator == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        require(newCreator != senderAddress, "newCreator is same as now");
        _creator = newCreator;
        emit CreatorChanged(senderAddress, newCreator);
    }
    
    function changePauseStatus(
        address senderAddress, 
        bool newValue
    ) public onlyOwner onlyCreator(senderAddress) {
        require(newValue != paused(), "newValue is same as now");
        if(newValue){
            _pause();
        } else {
            _unpause();
        }
        emit PauseStatusChanged(senderAddress, newValue);
    }

}