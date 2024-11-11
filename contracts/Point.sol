// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "./CRNAdmin.sol";

contract Point is ERC20, ERC20Pausable, CRNAdmin {
    string public constant CONTRACT = "CARINA_POINT_V1.0.0";
    ContractType public constant thisContractType = ContractType.POINT;

    uint8 private immutable _decimals;
    address public creator;
    bool public transferSwitch;
    uint256 public distributeLimit;

    mapping(address => uint256) private _lastBalanceUpdateTime;

    event CreatorChanged(
        address indexed previousCreator,
        address indexed newCreator
    );
    event DistributeLimitChanged(uint256 previousValue, uint256 newValue);
    event TransferSwitchUpdated(
        address indexed adminControlAddress,
        bool indexed newValue
    );

    modifier onlyCreator(address senderAddress) {
        require(
            senderAddress == creator,
            "senderAddress is not contract creator"
        );
        _;
    }

    constructor(
        address creatorAddress,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address adminControlAddress
    ) ERC20(name_, symbol_) {
        require(
            creatorAddress != address(0),
            "creatorAddress can not be zero address"
        );
        adminControl = adminControlAddress;
        creator = creatorAddress;
        _decimals = decimals_;
        distributeLimit = 100000 * (10 ** uint256(decimals_));
        transferSwitch = false;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function getAddressBalanceTimeStamp(
        address targetAddress
    ) external view returns (uint256, uint256) {
        return (
            balanceOf(targetAddress),
            _lastBalanceUpdateTime[targetAddress]
        );
    }

    function distribute(
        address userAddress,
        uint256 amount
    ) external onlyAdmin returns (bool) {
        require(
            amount > 0 && amount <= distributeLimit,
            "amount over the distribution limit"
        );
        _mint(userAddress, amount);
        return true;
    }

    function deduct(
        address userAddress,
        uint256 amount
    ) external onlyAdmin returns (bool) {
        require(amount > 0, "Invalid amount");
        _burn(userAddress, amount);
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
    ) internal override(ERC20, ERC20Pausable) {
        require(
            _isThisAdmin(msg.sender) || transferSwitch,
            "No authorization to transfer"
        );
        super._update(from, to, value);

        if (from != address(0)) {
            _lastBalanceUpdateTime[from] = block.timestamp;
        }
        if (to != address(0)) {
            _lastBalanceUpdateTime[to] = block.timestamp;
        }
    }

    function changeCreator(
        address senderAddress,
        address newCreator
    ) external onlyAdmin onlyCreator(senderAddress) returns (bool) {
        require(newCreator != address(0), "newCreator can not be zero address");
        require(newCreator != senderAddress, "newCreator is same as now");
        creator = newCreator;
        emit CreatorChanged(senderAddress, newCreator);
        return true;
    }

    function changePauseStatus(
        address senderAddress,
        bool newValue
    ) external onlyAdmin onlyCreator(senderAddress) returns (bool) {
        if (newValue) {
            _pause();
        } else {
            _unpause();
        }
        return true;
    }

    function setDistributeLimit(
        address senderAddress,
        uint256 newValue
    ) external onlyAdmin onlyCreator(senderAddress) returns (bool) {
        uint256 previousValue = distributeLimit;
        require(newValue != previousValue, "newValue is same as now");
        distributeLimit = newValue;
        emit DistributeLimitChanged(previousValue, newValue);
        return true;
    }

    function updateTransferSwitch() external {
        bool newValue = ICRNGeneric(adminControl).isContractTransferSwithOn(
            address(this)
        );
        transferSwitch = newValue;
        emit TransferSwitchUpdated(adminControl, newValue);
    }

    function updateAdmin() external {
        _updateAdmin(thisContractType);
    }
}
