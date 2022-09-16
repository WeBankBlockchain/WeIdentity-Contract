pragma solidity >=0.6.10 <0.8.20;
pragma experimental ABIEncoderV2;

/*
 *       Copyright© (2018) WeBank Co., Ltd.
 *
 *       Licensed under the Apache License, Version 2.0 (the "License");
 *       you may not use this file except in compliance with the License.
 *       You may obtain a copy of the License at

 *          http://www.apache.org/licenses/LICENSE-2.0
 *
 *       Unless required by applicable law or agreed to in writing, software
 *       distributed under the License is distributed on an "AS IS" BASIS,
 *       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *       See the License for the specific language governing permissions and
 *       limitations under the License.
 *      
 */
//SPDX-License-Identifier: Apache-2.0

/**
 * @title SpecificIssuerData
 * Stores data about issuers with specific types.
 */

contract SpecificIssuerData {

    // Error codes
    uint private RETURN_CODE_SUCCESS = 0;
    uint private RETURN_CODE_FAILURE_ALREADY_EXISTS = 500501;
    uint private RETURN_CODE_FAILURE_NOT_EXIST = 500502;
    uint private RETURN_CODE_FAILURE_EXCEED_MAX = 500503;
    uint private RETURN_CODE_FAILURE_NO_PERMISSION = 500000;
    uint private RETURN_CODE_FAILURE_DEL_EXIST_ISSUER = 500504;

    struct IssuerType {
        // typeName as index, dynamic array as getAt function and mapping as search
        bytes32 typeName;
        address[] fellow;
        bytes32[8] extra;
        address owner;
        uint256 created;
        mapping (address => bool) isFellow;
    }

    mapping (bytes32 => IssuerType) private issuerTypeMap;
    bytes32[] private typeNameArray;

    function registerIssuerType(bytes32 typeName) public returns (uint) {
        if (isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_ALREADY_EXISTS;
        }
        //IssuerType memory issuerType = IssuerType(typeName, fellow, extra);
        IssuerType storage issuerType = issuerTypeMap[typeName];
        issuerType.typeName = typeName;
        issuerType.owner = tx.origin;
        issuerType.created = block.timestamp;
        typeNameArray.push(typeName);
        return RETURN_CODE_SUCCESS;
    }
    
    function removeIssuerType(bytes32 typeName) public returns (uint) {
        if (!isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        if (issuerTypeMap[typeName].fellow.length != 0) {
            return RETURN_CODE_FAILURE_DEL_EXIST_ISSUER;
        }
        if (issuerTypeMap[typeName].owner != tx.origin) {
            return RETURN_CODE_FAILURE_NO_PERMISSION;
        }
        delete issuerTypeMap[typeName];
        uint datasetLength = typeNameArray.length;
        for (uint index = 0; index < datasetLength; index++) {
            if (typeNameArray[index] == typeName) {
                if (index != datasetLength-1) {
                    typeNameArray[index] = typeNameArray[datasetLength-1];
                }
                break;
            }
        }
        typeNameArray.pop();
        return RETURN_CODE_SUCCESS;
    }

    function getTypeNameSize() public view returns (uint) {
        return typeNameArray.length;
    }

    function getTypInfoByIndex(uint index) public view returns (bytes32, address, uint256) {
      bytes32 typeName = typeNameArray[index];
      return (typeName, issuerTypeMap[typeName].owner, issuerTypeMap[typeName].created);
    }

    function addExtraValue(bytes32 typeName, bytes32 extraValue) public returns (uint) {
        if (!isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        //IssuerType issuerType = issuerTypeMap[typeName];
        IssuerType storage issuerType = issuerTypeMap[typeName];
        for (uint index = 0; index < 8; index++) {
            if (issuerType.extra[index] == bytes32(0)) {
                issuerType.extra[index] = extraValue;
                break;
            }
            if (index == 7) {
                return RETURN_CODE_FAILURE_EXCEED_MAX;
            }
        }
        return RETURN_CODE_SUCCESS;
    }

    function getExtraValue(bytes32 typeName) public view returns (bytes32[8] memory) {
        bytes32[8] memory extraValues;
        if (!isIssuerTypeExist(typeName)) {
            return extraValues;
        }
        for (uint index = 0; index < 8; index++) {
            extraValues[index] = issuerTypeMap[typeName].extra[index];
        }
        return extraValues;
    }

    function isIssuerTypeExist(bytes32 name) public view returns (bool) {
        if (issuerTypeMap[name].typeName == bytes32(0)) {
            return false;
        }
        return true;
    }

    function addIssuer(bytes32 typeName, address addr) public returns (uint) {
        if (isSpecificTypeIssuer(typeName, addr)) {
            return RETURN_CODE_FAILURE_ALREADY_EXISTS;
        }
        if (!isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        issuerTypeMap[typeName].fellow.push(addr);
        issuerTypeMap[typeName].isFellow[addr] = true;
        return RETURN_CODE_SUCCESS;
    }

    function removeIssuer(bytes32 typeName, address addr) public returns (uint) {
        if (!isSpecificTypeIssuer(typeName, addr) || !isIssuerTypeExist(typeName)) {
            return RETURN_CODE_FAILURE_NOT_EXIST;
        }
        address[] memory fellow = issuerTypeMap[typeName].fellow;
        uint dataLength = fellow.length;
        for (uint index = 0; index < dataLength; index++) {
            if (addr == fellow[index]) {
                if (index != dataLength-1) {
                    issuerTypeMap[typeName].fellow[index] = issuerTypeMap[typeName].fellow[dataLength-1];
                }
                break;
            }
        }
        issuerTypeMap[typeName].fellow.pop();
        issuerTypeMap[typeName].isFellow[addr] = false;
        return RETURN_CODE_SUCCESS;
    }

    function isSpecificTypeIssuer(bytes32 typeName, address addr) public view returns (bool) {
        if (issuerTypeMap[typeName].isFellow[addr] == false) {
            return false;
        }
        return true;
    }

    function getSpecificTypeIssuers(bytes32 typeName, uint startPos) public view returns (address[50] memory) {
        address[50] memory fellow;
        if (!isIssuerTypeExist(typeName)) {
            return fellow;
        }

        // Calculate actual dataLength via batch return for better perf
        uint totalLength = getSpecificTypeIssuerLength(typeName);
        uint dataLength;
        if (totalLength < startPos) {
            return fellow;
        } else if (totalLength <= startPos + 50) {
            dataLength = totalLength - startPos;
        } else {
            dataLength = 50;
        }

        // dynamic -> static array data copy
        for (uint index = 0; index < dataLength; index++) {
            fellow[index] = issuerTypeMap[typeName].fellow[index + startPos];
        }
        return fellow;
    }

    function getSpecificTypeIssuerLength(bytes32 typeName) public view returns (uint) {
        if (!isIssuerTypeExist(typeName)) {
            return 0;
        }
        return issuerTypeMap[typeName].fellow.length;
    }
}