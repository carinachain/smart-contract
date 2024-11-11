// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Point.sol";
import "./CRNFactory.sol";

contract PointFactory is Initializable, CRNFactory {
    ContractType public constant thisContractType = ContractType.POINTFACTORY;
    string public CONTRACTVERSION;

    uint256[50] private __gap;

    event PointCreated(
        address indexed contractAddress,
        address indexed creator,
        address indexed sender
    );

    constructor() {
        _disableInitializers();
    }

    function initialize(address adminControlAddress) public initializer {
        adminControl = adminControlAddress;
        CONTRACTVERSION = "CARINA_POINTFACTORY_V1.0.0";
    }

    function createPoint(
        address creatorAddress,
        string memory name,
        string memory symbol,
        uint8 decimals
    ) external onlyAdmin returns (address) {
        require(
            !_isOverCreationTypeLimit(creatorAddress, ContractType.POINT),
            "creatorAddress reached Point create limit"
        );
        Point newContract = new Point(
            creatorAddress,
            name,
            symbol,
            decimals,
            adminControl
        );
        newContract.updateAdmin();
        address newContractAddress = address(newContract);
        ICRNGeneric(adminControl).whenCreationCreated(
            creatorAddress,
            ContractType.POINT,
            newContractAddress
        );
        _SenderCreatedContractList[msg.sender].push(newContractAddress);
        emit PointCreated(newContractAddress, creatorAddress, msg.sender);
        return newContractAddress;
    }

    function updateAdmin() external {
        _updateAdmin(thisContractType);
    }
}
