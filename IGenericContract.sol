// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ShareEnums.sol";

interface IGenericContract is IERC20Metadata {
    
    // Contract type
    function thisContractType() external view returns (ContractType);
    
    // Creator
    function creator() external view returns (address);  

    // Owner
    function owner() external view returns (address);

    // Paused status
    function paused() external view returns (bool);

    // Transfer switch status
    function transferSwitchStatus() external view returns (bool);
    
    // Auto mint status
    function distributeLimitInfo() external view returns (uint256);

    // Mint switch status
    function mintSwitchStatus() external view returns (bool);

    // tokenValue
    function thisTokenValue() external view returns (TokenValue memory);

}
