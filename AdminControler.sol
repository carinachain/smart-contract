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

    event AdminAddressAdded(ContractType indexed creationType, address indexed addAdminAddress);
    event AdminAddressRemoved(ContractType indexed creationType, address indexed removeAdminAddress);
    event ContractAddressSet(ContractType indexed contractType, address indexed newContractAddress, address indexed previousContractAddress);
    event CreationLimitSet(ContractType indexed contractType, uint256 newCreationLimit, uint256 previousCreationLimit);

    modifier notZeroAddress(address targetAddress) {
        require(targetAddress != address(0), "Invalid address");
        _;
    }

    modifier notUndefinedType(ContractType contractType) {
        require(contractType != ContractType.UNDEFINED, "Invalid type");
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
        require(_AdminStatusList[contractType][addAdminAddress] == false, "Already added");
        _AdminStatusList[contractType][addAdminAddress] = true; 
        _CreationTypeAdminList[contractType].push(addAdminAddress); 
        emit AdminAddressAdded(contractType, addAdminAddress);
    } 

    // remove admin
    function removeAdmin(
        address removeAdminAddress, 
        ContractType contractType
    ) external onlyOwner notZeroAddress(removeAdminAddress) notUndefinedType(contractType) {
        require(_AdminStatusList[contractType][removeAdminAddress] == true, "Not in the list");
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
        require(contractAddress != previousContractAddress, "Already set");
        _ContractAddressBook[contractType] = contractAddress;
        emit ContractAddressSet(contractType, contractAddress, previousContractAddress);
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
        uint256 newCreationLimit
    ) external onlyOwner notUndefinedType(targetType) {
        uint256 previousCreationLimit = _CreationTypeLimit[targetType];
        require(newCreationLimit != previousCreationLimit, "Already set");
        _CreationTypeLimit[targetType] = newCreationLimit;
        emit CreationLimitSet(targetType, newCreationLimit, previousCreationLimit);
    }

    // get creation limit info by type
    function getCreationLimit(
        ContractType targetType
    ) external view notUndefinedType(targetType) returns (uint256) {
        return _CreationTypeLimit[targetType];
    }

}