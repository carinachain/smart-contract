// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./interfaces/ICRNGeneric.sol";

contract CRNProxyForContract is ERC1967Proxy {
    string public constant COPYRIGHT_ =
        "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV_ = "NebulaInfinity.com";
    ContractType public immutable proxyContractType;

    address public adminControlAddressForProxy;

    modifier onlyAdminControlAdmin() {
        require(
            ICRNGeneric(adminControlAddressForProxy).adminStatus(
                ContractType.ADMINCONTROL,
                msg.sender
            ),
            "Need AdminControlAdmin"
        );
        _;
    }

    constructor(
        address logic,
        address adminControlAddress
    )
        ERC1967Proxy(
            logic,
            abi.encodeWithSignature("initialize(address)", adminControlAddress)
        )
    {
        adminControlAddressForProxy = adminControlAddress;
        proxyContractType = ICRNGeneric(logic).thisContractType();
    }

    function upgradeTo(
        address newImplementation,
        bytes memory data
    ) external onlyAdminControlAdmin {
        require(
            proxyContractType ==
                ICRNGeneric(newImplementation).thisContractType(),
            "newImplementation is not same contract type as current"
        );
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }

    function getImplementation() external view returns (address) {
        return _implementation();
    }

    function updateAdminControlAddressForProxy() public {
        address newControlAddress = ICRNGeneric(adminControlAddressForProxy)
            .contractAddressBook(ContractType.ADMINCONTROL);
        require(
            newControlAddress != address(0),
            "adminControl do not have new control address"
        );
        address previousControlAddress = adminControlAddressForProxy;
        require(
            newControlAddress != previousControlAddress,
            "No need update adminControl"
        );
        adminControlAddressForProxy = newControlAddress;
    }

    receive() external payable {}
}
