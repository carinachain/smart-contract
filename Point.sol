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

    // TokenValue private _thisTokenValue;

    uint256 private _distributeLimit;

    bool private _mintSwitch;
    
    bool private _transferSwitch;

    event Distributed(address indexed senderAddress, address indexed userAddress, uint256 amount);
    event Deducted(address indexed senderAddress, address indexed userAddress, uint256 amount);
    event MintSwitchChanged(address senderAddress, bool indexed newValue);
    event TransferSwitchChanged(bool indexed newValue);
    event DistributeLimitChanged(uint indexed priviousValue, uint indexed newValue);
    event CreatorChanged(address indexed newCreator, address indexed previousCreator );
    event PauseStatusChanged(address senderAddress, bool indexed newValue);

    modifier onlyCreator(address senderAddress) {
        require(senderAddress == _creator, "Only for creator");
        _;
    }


    constructor (
        address creatorAddress_, 
        ContractType createContractType, 
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_
        // uint256 valueAmount_,
        // string memory valueCurrency_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        if (creatorAddress_ == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        require(createContractType != ContractType.UNDEFINED, "Invalid type");

        _creator = creatorAddress_;
        _decimals = decimals_;
        thisContractType = createContractType;
        // _thisTokenValue = TokenValue(valueAmount_, valueCurrency_);

        // default distributeLimit is 100000
        _distributeLimit = 100000 * (10 ** uint256(decimals_));

        // default mint switch is on
        _mintSwitch = true;

        // default transfer switch off only permit transfer through owner 
        _transferSwitch = false;

    }

    // get decimals
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // this contract TokenValue
    // function thisTokenValue() external view returns (TokenValue memory) {
    //     return _thisTokenValue;
    // }

    // distribution
    function distribute(
        address senderAddress, 
        address userAddress, 
        uint256 amount
    ) external  onlyOwner {
        require(_mintSwitch, "Mint stoped");
        require(amount != 0, "Invalid amount");
        require(amount <= _distributeLimit, "Amount reached distribute limit");

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
    function pTransfer(address from, address to, uint256 amount) external onlyOwner returns (bool) {
        _transfer(from, to, amount);
        return true;
    }

    // get distribute limit info
    function distributeLimitInfo() external view returns (uint256) {
        return _distributeLimit;
    }

    // change distribte limit
    function changeDistributeLimit(
        address senderAddress, 
        uint256 newValue
    ) external onlyOwner onlyCreator(senderAddress) {
        uint256 priviousDistribueLimit = _distributeLimit;
        require(newValue != priviousDistribueLimit);
        _distributeLimit = newValue;
        emit DistributeLimitChanged(priviousDistribueLimit, newValue);
    }

    // get mint switch's status
    function mintSwitchStatus() external view returns (bool) {
        return _mintSwitch;
    }

    // mint switch setting
    function setMintSwitch(
        address senderAddress, 
        bool value
    ) external onlyOwner onlyCreator(senderAddress) {
        require(value != _mintSwitch, "Already set");
        _mintSwitch = value;
        emit MintSwitchChanged(senderAddress, value);
    }

    // get transfer switch's status
    function transferSwitchStatus() external view returns (bool) {
        return _transferSwitch;
    }

    // transfer switch setting
    function setTransferSwitch(bool value) external onlyOwner {
        require(value != _transferSwitch, "Already set");
        _transferSwitch = value;
        emit TransferSwitchChanged(value);
    }

    // switch off: only can transfer through owner; switch on: can transfer by user-self 
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        require(msg.sender == owner() || _transferSwitch, "No authorization to transfer");
        super._update(from, to, value);
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
        require(newCreator != senderAddress, "Already set");
        _creator = newCreator;
        emit CreatorChanged(newCreator, senderAddress);
    }
    
    function changePauseStatus(
        address senderAddress, 
        bool value
    ) public onlyOwner onlyCreator(senderAddress) {
        require(value != paused(), "Already set");
        if(value){
            _pause();
        } else {
            _unpause();
        }
        emit PauseStatusChanged(senderAddress, value);
    }

}