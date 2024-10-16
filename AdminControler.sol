// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ShareEnums.sol";
import "./IGenericContract.sol";

contract AdminControler is Ownable  {
    string public constant COPYRIGHT = "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV = "NebulaInfinity.com";
    ContractType public constant thisContractType = ContractType.ADMINCONTROLER;

    mapping(ContractType => mapping(address => bool)) private _AdminStatusList;
    mapping(ContractType => address[]) private _CreationTypeAdminList;
    mapping(ContractType => address) private _ContractAddressBook;
    mapping(ContractType => uint256) internal _CreationTypeLimit;
    mapping(bytes32 => uint256) private _FunctionExpenseList;

    event AdminAddressAdded(ContractType indexed creationType, address indexed addAdminAddress);
    event AdminAddressRemoved(ContractType indexed creationType, address indexed removeAdminAddress);
    event ContractAddressSet(ContractType indexed contractType, address indexed previousContractAddress, address indexed newContractAddress);
    event CreationLimitSet(ContractType indexed contractType, uint256 previousValue, uint256 newValue);
    event FunctionExpenseSet(address indexed contractAddress, string functionName, uint256 previousValue, uint256 newValue);

    modifier notZeroAddress(address targetAddress) {
        require(targetAddress != address(0), "Invalid address");
        _;
    }

    modifier notUndefinedType(ContractType contractType) {
        require(contractType != ContractType.UNDEFINED, "Invalid contractType");
        _;
    }

    // owner is admin address
    constructor(address ownerAddress, address CRNAddress) Ownable(ownerAddress) {
        _AdminStatusList[ContractType.POINTFACTORY][ownerAddress] = true;
        _CreationTypeAdminList[ContractType.POINTFACTORY].push(ownerAddress);

        _AdminStatusList[ContractType.USERMANAGER][ownerAddress] = true;
        _CreationTypeAdminList[ContractType.USERMANAGER].push(ownerAddress);

        _CreationTypeLimit[ContractType.POINT] = 1;

        _ContractAddressBook[ContractType.ADMINCONTROLER] = address(this);

        _ContractAddressBook[ContractType.CRNTOKEN] = CRNAddress;
    }

    // set admin for contract type
    function addAdmin(
        address addAdminAddress, 
        ContractType contractType
    ) external onlyOwner notZeroAddress(addAdminAddress) notUndefinedType(contractType) {
        require(_AdminStatusList[contractType][addAdminAddress] == false, "addAdminAddress already added");
        _AdminStatusList[contractType][addAdminAddress] = true; 
        _CreationTypeAdminList[contractType].push(addAdminAddress); 
        emit AdminAddressAdded(contractType, addAdminAddress);
    } 

    // remove admin
    function removeAdmin(
        address removeAdminAddress, 
        ContractType contractType
    ) external onlyOwner notZeroAddress(removeAdminAddress) notUndefinedType(contractType) {
        require(_AdminStatusList[contractType][removeAdminAddress] == true, "removeAdminAddress is not in the Admin list");
        _AdminStatusList[contractType][removeAdminAddress] = false;
        for (uint i = 0; i < _CreationTypeAdminList[contractType].length; i++) {
            if (_CreationTypeAdminList[contractType][i] == removeAdminAddress) {
                _CreationTypeAdminList[contractType][i] = _CreationTypeAdminList[contractType][_CreationTypeAdminList[contractType].length - 1];
                _CreationTypeAdminList[contractType].pop();
                emit AdminAddressRemoved(contractType, removeAdminAddress);
                break;
            }
        }
    }

    // get admin list
    function getAdminList(
        ContractType contractType
    ) external view onlyOwner notUndefinedType(contractType) returns (address[] memory) {
        return _CreationTypeAdminList[contractType]; 
    }

    // check if address is admin for this creation type 
    function checkAdmin(
        address checkAddress, 
        ContractType contractType
    ) external notZeroAddress(checkAddress) notUndefinedType(contractType) view returns (bool) {
        return _AdminStatusList[contractType][checkAddress]; 
    }

    // change contract address book
    function setContractAddress( 
        address contractAddress
    ) external onlyOwner notUndefinedType(IGenericContract(contractAddress).thisContractType()) {
        ContractType contractType = IGenericContract(contractAddress).thisContractType();
        address previousContractAddress = _ContractAddressBook[contractType];
        require(contractAddress != previousContractAddress, "contractAddress already set");
        _ContractAddressBook[contractType] = contractAddress;
        emit ContractAddressSet(contractType, previousContractAddress, contractAddress);
    }

    // get contract address
    function getContractAddress(
        ContractType contractType
    ) external view notUndefinedType(contractType) returns (address) {
        return _ContractAddressBook[contractType];
    }

    // set creation limit. when limit value is 0, creation & creatorchange will be stopped
    function setCreationLimit(
        ContractType targetType, 
        uint256 newCreationLimitValue
    ) external onlyOwner notUndefinedType(targetType) {
        uint256 previousCreationLimitValue = _CreationTypeLimit[targetType];
        require(newCreationLimitValue != previousCreationLimitValue, "newCreationLimitValue is same as now");
        _CreationTypeLimit[targetType] = newCreationLimitValue;
        emit CreationLimitSet(targetType, previousCreationLimitValue, newCreationLimitValue);
    }

    // get creation limit info by type
    function getCreationLimit(
        ContractType targetType
    ) external view notUndefinedType(targetType) returns (uint256) {
        return _CreationTypeLimit[targetType];
    }

    function getFunctionExpense(
        address contractAddress,
        string calldata functionName
    ) external view notUndefinedType(IGenericContract(contractAddress).thisContractType()) returns (uint256) {
        return _FunctionExpenseList[keccak256(abi.encodePacked(contractAddress, functionName))];
    }

    function setFunctionExpense(
        address contractAddress, 
        string calldata functionName, 
        uint256 newExpenseValue
    ) external onlyOwner notUndefinedType(IGenericContract(contractAddress).thisContractType()) {
        uint256 previousExpenseValue = _FunctionExpenseList[keccak256(abi.encodePacked(contractAddress, functionName))];
        require(newExpenseValue != previousExpenseValue, "newExpenseValue is same as now");
        _FunctionExpenseList[keccak256(abi.encodePacked(contractAddress, functionName))] = newExpenseValue;
        emit FunctionExpenseSet(contractAddress, functionName, previousExpenseValue, newExpenseValue);
    }

    function isInsufficientCredit(
        address payerAddress,
        address contractAddress,
        string memory functionName
    ) external view returns (bool) {
        return (
            IGenericContract(_ContractAddressBook[ContractType.CREDITPOINT]).balanceOf(payerAddress) < _FunctionExpenseList[keccak256(abi.encodePacked(contractAddress, functionName))]
        );
    }

}