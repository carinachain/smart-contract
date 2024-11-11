// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./CRNAdmin.sol";

contract Membership is CRNAdmin {
    string public constant CONTRACT = "CARINA_MEMBERSHIP_V1.0.0";
    ContractType public constant thisContractType = ContractType.MEMBERSHIP;

    address public creator;

    mapping(uint256 => string) public levelName;
    mapping(address => uint256) private _memberLevel;

    mapping(address => bool) public hasMembership;
    mapping(uint256 => address[]) private _membersList;

    event MembershipIssued(
        address indexed senderAddress,
        address memberAddress
    );
    event MembershipRevoked(
        address indexed senderAddress,
        address memberAddress
    );
    event MemberLevelChanged(
        address indexed senderAddress,
        address memberAddress
    );
    event CreatorChanged(
        address indexed previousCreator,
        address indexed newCreator
    );

    modifier onlyCreator(address senderAddress) {
        require(
            senderAddress == creator,
            "senderAddress is not contract creator"
        );
        _;
    }

    constructor(address creatorAddress, address adminControlAddress) {
        creator = creatorAddress;
        adminControl = adminControlAddress;
    }

    function defineLevelBatch(
        address senderAddress,
        uint256[] memory levelNumberArray,
        string[] memory levelNameList
    ) external onlyAdmin onlyCreator(senderAddress) returns (bool) {
        require(
            levelNumberArray.length == levelNameList.length,
            "number of levels not match to name list"
        );
        for (uint i = 0; i < levelNumberArray.length; i++) {
            uint256 currentLevel = levelNumberArray[i];
            string memory currentLevelName = levelNameList[i];
            require(currentLevel > 0, "levelNumberArray include zero number");
            require(
                bytes(currentLevelName).length > 0,
                "levelNameList include empty data"
            );
            require(
                keccak256(abi.encodePacked(levelName[currentLevel])) !=
                    keccak256(abi.encodePacked(currentLevelName)),
                "include already defined data"
            );
            levelName[currentLevel] = currentLevelName;
        }
        return true;
    }

    function defineLevel(
        address senderAddress,
        uint256 levelNumber,
        string memory targetlevelName
    ) external onlyAdmin onlyCreator(senderAddress) returns (bool) {
        require(levelNumber > 0, "levelNumber can not be zero");
        require(
            bytes(targetlevelName).length > 0 ||
                bytes(levelName[levelNumber]).length > 0,
            "targetlevelName can not be empty"
        );
        require(
            keccak256(abi.encodePacked(levelName[levelNumber])) !=
                keccak256(abi.encodePacked(targetlevelName)),
            "levelNumber is already be defined by same levelName"
        );
        levelName[levelNumber] = targetlevelName;
        return true;
    }

    function _removeFromMemberList(
        address memberAddress,
        uint256 memberlevel
    ) internal {
        address[] storage membersListArray = _membersList[memberlevel];
        for (uint i = 0; i < membersListArray.length; i++) {
            if (membersListArray[i] == memberAddress) {
                membersListArray[i] = membersListArray[
                    membersListArray.length - 1
                ];
                membersListArray.pop();
                break;
            }
        }
    }

    function issueMembership(
        address senderAddress,
        address memberAddress,
        uint256 level
    ) external onlyAdmin returns (bool) {
        require(bytes(levelName[level]).length > 0, "level is not be defined");
        require(hasMembership[memberAddress] == false, "member already issued");
        hasMembership[memberAddress] = true;
        _membersList[level].push(memberAddress);
        _memberLevel[memberAddress] = level;
        emit MembershipIssued(senderAddress, memberAddress);
        return true;
    }

    function revokeMembership(
        address senderAddress,
        address memberAddress
    ) external onlyAdmin returns (bool) {
        require(
            hasMembership[memberAddress] == true,
            "only exist member can be revoked"
        );
        uint256 currentLevel = _memberLevel[memberAddress];
        _removeFromMemberList(memberAddress, currentLevel);
        _membersList[0].push(memberAddress);
        hasMembership[memberAddress] = false;
        emit MembershipRevoked(senderAddress, memberAddress);
        return true;
    }

    function getMemberList(
        uint256 level
    ) external view onlyAdmin returns (address[] memory) {
        return _membersList[level];
    }

    function getMemberInfo(
        address memberAddress
    ) external view onlyAdmin returns (bool, uint256) {
        return (hasMembership[memberAddress], _memberLevel[memberAddress]);
    }

    function changeMemberLevel(
        address senderAddress,
        address memberAddress,
        uint level
    ) external onlyAdmin returns (bool) {
        require(bytes(levelName[level]).length > 0, "level is not be defined");
        require(hasMembership[memberAddress] == true, "only exist member");
        uint256 currentLevel = _memberLevel[memberAddress];
        require(currentLevel != level, "invalid level value");
        _memberLevel[memberAddress] = level;
        _removeFromMemberList(memberAddress, currentLevel);
        _membersList[level].push(memberAddress);
        emit MemberLevelChanged(senderAddress, memberAddress);
        return true;
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

    function updateAdmin() external {
        _updateAdmin(thisContractType);
    }
}
