// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./interfaces/ICRNGeneric.sol";

contract CRNProxyForAdminControl is ERC1967Proxy {
    string public constant COPYRIGHT_ =
        "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV_ = "NebulaInfinity.com";
    ContractType public immutable proxyContractType;

    modifier onlyProxyAdmin() {
        require(msg.sender == ERC1967Utils.getAdmin(), "Must be ProxyAdmin");
        _;
    }

    constructor(
        address logic,
        address ownerAddress,
        address CRNAddress
    )
        ERC1967Proxy(
            logic,
            abi.encodeWithSignature(
                "initialize(address,address)",
                ownerAddress,
                CRNAddress
            )
        )
    {
        ERC1967Utils.changeAdmin(ownerAddress);
        proxyContractType = ICRNGeneric(logic).thisContractType();
    }

    function upgradeTo(
        address newImplementation,
        bytes memory data
    ) external onlyProxyAdmin {
        require(
            proxyContractType ==
                ICRNGeneric(newImplementation).thisContractType(),
            "newImplementation is not same contract type as current"
        );
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }

    function setProxyAdmin(address newProxyAdmin) external onlyProxyAdmin {
        require(
            newProxyAdmin != ERC1967Utils.getAdmin(),
            "newProxyAdmin is same as now"
        );
        ERC1967Utils.changeAdmin(newProxyAdmin);
    }

    function getImplementation() external view returns (address) {
        return _implementation();
    }

    receive() external payable {}
}
