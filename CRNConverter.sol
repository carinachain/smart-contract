// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./UserManager.sol";
import "./AdminControler.sol";
import "./ShareEnums.sol";
import "./PointFactory.sol";

contract CRNConverter {

    string public constant COPYRIGHT = "Copyright (c) 2024 CarinaChain.com All rights reserved.";
    string public constant DEV = "NebulaInfinity.com";
    ContractType public constant thisContractType = ContractType.CRNCONVERTER;

    AdminControler private  adminControler;
    PointFactory private pointFactory;
    address private CRNAddress;
    address private pCRNAddress;

    event PCRNMited(address indexed sender, uint256 amount);
    event CRNWithdrew(address indexed sender, uint256 amount);

    modifier onlyConverterAdmin() {
        require(adminControler.checkAdmin(msg.sender, thisContractType), "Need admin");
        _;
    }

    modifier onlyRegisteredUser(address userAddress) {
        require(userAddress != address(0), "Invalid address");
        require(uint8(UserManager(adminControler.getContractAddress(ContractType.USERMANAGER)).getUserType(userAddress)) > 1, "Only for registered user");
        _;
    }


    
    constructor(address adminControlerAddress) {
        adminControler = AdminControler(adminControlerAddress);
        pointFactory = PointFactory(adminControler.getContractAddress(ContractType.POINTFACTORY));
        CRNAddress = adminControler.getContractAddress(ContractType.CRNTOKEN);
        pCRNAddress = adminControler.getContractAddress(ContractType.POINTCRN);
    }

    // Deposit CRN in contract to mint pointCRN (need approve mint amout to contract first)
    function mintpCRN(
        uint256 mintAmount
    ) external onlyRegisteredUser(msg.sender) {
        require(IERC20(CRNAddress).transferFrom(msg.sender, address(this), mintAmount), "CRN transfer failed");
        pointFactory.distributePoint(pCRNAddress, address(this), msg.sender, mintAmount);
        emit PCRNMited(msg.sender, mintAmount);
    }

    // Burn pCRN withdraw CRN, need pay fee
    function withdrawCRN(
        address senderAddress, 
        uint256 withdrawAmount, 
        uint256 feeAmount
    ) external onlyConverterAdmin onlyRegisteredUser(senderAddress){
        pointFactory.transferPoint(adminControler.getContractAddress(ContractType.CREDITPOINT), senderAddress, address(this), feeAmount);
        pointFactory.deductPoint(pCRNAddress, address(this), senderAddress, withdrawAmount);  //check senderAddress withdrawAmount
        IERC20(CRNAddress).transfer(senderAddress, withdrawAmount);
        emit CRNWithdrew(senderAddress, withdrawAmount);
    }

}