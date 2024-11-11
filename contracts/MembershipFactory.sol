// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Membership.sol";
import "./CRNFactory.sol";

contract MembershipFactory is Initializable, CRNFactory {
    ContractType public constant thisContractType =
        ContractType.MEMBERSHIPFACTORY;
    string public CONTRACTVERSION;

    uint256[50] private __gap;

    event MembershipCreated(
        address indexed contractAddress,
        address indexed creator,
        address indexed sender
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(address adminControlAddress) public initializer {
        adminControl = adminControlAddress;
        CONTRACTVERSION = "CARINA_MEMBERSHIPFACTORY_V1.0.0";
    }

    function createMembership(
        address creatorAddress
    ) external onlyAdmin returns (address) {
        require(
            !_isOverCreationTypeLimit(creatorAddress, ContractType.MEMBERSHIP),
            "creatorAddress reached Membership create limit"
        );
        Membership newContract = new Membership(creatorAddress, adminControl);
        newContract.updateAdmin();
        address newContractAddress = address(newContract);
        ICRNGeneric(adminControl).whenCreationCreated(
            creatorAddress,
            ContractType.MEMBERSHIP,
            newContractAddress
        );
        _SenderCreatedContractList[msg.sender].push(newContractAddress);
        emit MembershipCreated(newContractAddress, creatorAddress, msg.sender);
        return newContractAddress;
    }

    function updateAdmin() external {
        _updateAdmin(thisContractType);
    }
}
