pragma solidity ^0.4.4;
/*
 *       Copyright© (2019) WeBank Co., Ltd.
 *
 *       This file is part of weidentity-contract.
 *
 *       weidentity-contract is free software: you can redistribute it and/or modify
 *       it under the terms of the GNU Lesser General Public License as published by
 *       the Free Software Foundation, either version 3 of the License, or
 *       (at your option) any later version.
 *
 *       weidentity-contract is distributed in the hope that it will be useful,
 *       but WITHOUT ANY WARRANTY; without even the implied warranty of
 *       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *       GNU Lesser General Public License for more details.
 *
 *       You should have received a copy of the GNU Lesser General Public License
 *       along with weidentity-contract.  If not, see <https://www.gnu.org/licenses/>.
 */

/**
 * @title SpecificIssuerData
 * Stores data about issuers with specific types.
 */

contract SpecificIssuerData {
    struct IssuerType {
        // typeName as index, dynamic array as getAt function and mapping as search
        bytes32 typeName;
        address[] member;
        mapping (address => bool) isMember;
    }

    mapping (bytes32 => IssuerType) private issuerTypeMap;

    function registerIssuerType(bytes32 typeName) public returns (bool) {
        if (isIssuerTypeExist(typeName)) {
            return false;
        }
        address[] memory member;
        IssuerType memory issuerType = IssuerType(typeName, member);
        issuerTypeMap[typeName] = issuerType;
        return true;
    }

    function isIssuerTypeExist(bytes32 name) public constant returns (bool) {
        if (issuerTypeMap[name].typeName == bytes32(0)) {
            return false;
        }
        return true;
    }

    function addIssuer(bytes32 typeName, address addr) public returns (bool) {
        if (isSpecificTypeIssuer(typeName, addr) || !isIssuerTypeExist(typeName)) {
            return false;
        }
        issuerTypeMap[typeName].member.push(addr);
        issuerTypeMap[typeName].isMember[addr] = true;
        return true;
    }

    function removeIssuer(bytes32 typeName, address addr) public returns (bool) {
        if (!isSpecificTypeIssuer(typeName, addr) || !isIssuerTypeExist(typeName)) {
            return false;
        }
        address[] memory member = issuerTypeMap[typeName].member;
        uint dataLength = member.length;
        for (uint index = 0; index < dataLength; index++) {
            if (addr == member[index]) {
                break;
            }
        }
        if (index != dataLength-1) {
            issuerTypeMap[typeName].member[index] = issuerTypeMap[typeName].member[dataLength-1];
        }
        delete issuerTypeMap[typeName].member[dataLength-1];
        issuerTypeMap[typeName].member.length--;
        issuerTypeMap[typeName].isMember[addr] = false;
        return true;
    }

    function isSpecificTypeIssuer(bytes32 typeName, address addr) public constant returns (bool) {
        if (issuerTypeMap[typeName].isMember[addr] == false) {
            return false;
        }
        return true;
    }

    function getSpecificTypeIssuerMembers(bytes32 typeName, uint startPos) public constant returns (address[50]) {
        address[50] memory member;
        if (!isIssuerTypeExist(typeName)) {
            return member;
        }

        // Calculate actual dataLength via batch return for better perf
        uint totalLength = getSpecificTypeIssuerMemberLength(typeName);
        uint dataLength;
        if (totalLength < startPos) {
            return member;
        } else if (totalLength <= startPos + 50) {
            dataLength = totalLength - startPos;
        } else {
            dataLength = 50;
        }

        // dynamic -> static array data copy
        for (uint index = 0; index < dataLength; index++) {
            member[index] = issuerTypeMap[typeName].member[index + startPos];
        }
        return member;
    }

    function getSpecificTypeIssuerMemberLength(bytes32 typeName) public constant returns (uint) {
        if (!isIssuerTypeExist(typeName)) {
            return 0;
        }
        return issuerTypeMap[typeName].member.length;
    }
}