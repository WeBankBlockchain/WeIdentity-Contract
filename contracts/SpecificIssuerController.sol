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

import "./SpecificIssuerData.sol";
import "./RoleController.sol";

/**
 * @title SpecificIssuerController
 * Controller contract managing issuers with specific types info.
 */

contract SpecificIssuerController {

    SpecificIssuerData private specificIssuerData;
    RoleController private roleController;

    // Event structure to store tx records
    uint private OPERATION_ADD = 0;
    uint private OPERATION_REMOVE = 1;

    event SpecificIssuerRetLog(uint operation, uint retCode, bytes32 typeName, address addr);

    // Constructor.
    constructor(
        address specificIssuerDataAddress,
        address roleControllerAddress
    )
        public
    {
        specificIssuerData = SpecificIssuerData(specificIssuerDataAddress);
        roleController = RoleController(roleControllerAddress);
    }

    function registerIssuerType(bytes32 typeName) public {
        uint result = specificIssuerData.registerIssuerType(typeName);
        emit SpecificIssuerRetLog(OPERATION_ADD, result, typeName, address(0));
    }

    function isIssuerTypeExist(bytes32 typeName) public view returns (bool) {
        return specificIssuerData.isIssuerTypeExist(typeName);
    }

    function addIssuer(bytes32 typeName, address addr) public {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
            emit SpecificIssuerRetLog(OPERATION_ADD, roleController.RETURN_CODE_FAILURE_NO_PERMISSION(), typeName, addr);
            return;
        }
        uint result = specificIssuerData.addIssuer(typeName, addr);
        emit SpecificIssuerRetLog(OPERATION_ADD, result, typeName, addr);
    }

    function removeIssuer(bytes32 typeName, address addr) public {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
            emit SpecificIssuerRetLog(OPERATION_REMOVE, roleController.RETURN_CODE_FAILURE_NO_PERMISSION(), typeName, addr);
            return;
        }
        uint result = specificIssuerData.removeIssuer(typeName, addr);
        emit SpecificIssuerRetLog(OPERATION_REMOVE, result, typeName, addr);
    }

    function addExtraValue(bytes32 typeName, bytes32 extraValue) public {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
            emit SpecificIssuerRetLog(OPERATION_ADD, roleController.RETURN_CODE_FAILURE_NO_PERMISSION(), typeName, address(0));
            return;
        }
        uint result = specificIssuerData.addExtraValue(typeName, extraValue);
        emit SpecificIssuerRetLog(OPERATION_ADD, result, typeName, address(0));
    }

    function getExtraValue(bytes32 typeName) public view returns (bytes32[] memory) {
        bytes32[8] memory tempArray = specificIssuerData.getExtraValue(typeName);
        bytes32[] memory resultArray = new bytes32[](8);
        for (uint index = 0; index < 8; index++) {
            resultArray[index] = tempArray[index];
        }
        return resultArray;
    }

    function isSpecificTypeIssuer(bytes32 typeName, address addr) public view returns (bool) {
        return specificIssuerData.isSpecificTypeIssuer(typeName, addr);
    }

    function getSpecificTypeIssuerList(bytes32 typeName, uint startPos, uint num) public view returns (address[] memory) {
        if (num == 0 || !specificIssuerData.isIssuerTypeExist(typeName)) {
            return new address[](50);
        }

        // Calculate actual dataLength via batch return for better perf
        uint totalLength = specificIssuerData.getSpecificTypeIssuerLength(typeName);
        uint dataLength;
        if (totalLength < startPos) {
            return new address[](50);
        } else {
            if (totalLength <= startPos + num) {
                dataLength = totalLength - startPos;
            } else {
                dataLength = num;
            }
        }

        address[] memory resultArray = new address[](dataLength);
        address[50] memory tempArray;
        tempArray = specificIssuerData.getSpecificTypeIssuers(typeName, startPos);
        uint tick;
        if (dataLength <= 50) {
            for (tick = 0; tick < dataLength; tick++) {
                resultArray[tick] = tempArray[tick];
            }
        } else {
            for (tick = 0; tick < 50; tick++) {
                resultArray[tick] = tempArray[tick];
            }
        }
        return resultArray;
    }
    
    function getSpecificTypeIssuerSize(bytes32 typeName) public view returns (uint) {
        return specificIssuerData.getSpecificTypeIssuerLength(typeName);
    }

    function getIssuerTypeList(
        uint startPos,
        uint num
    )
        public
        view
        returns (bytes32[] memory, address[] memory, uint256[] memory)
    {
        uint totalLength = specificIssuerData.getTypeNameSize();

        uint dataLength;
        // Calculate actual dataLength
        if (totalLength < startPos) {
          return (new bytes32[](0), new address[](0), new uint256[](0));
        } else if (totalLength <= startPos + num) {
          dataLength = totalLength - startPos;
        } else {
          dataLength = num;
        }

        bytes32[] memory typeNames = new bytes32[](dataLength);
        address[] memory owners = new address[](dataLength);
        uint256[] memory createds = new uint256[](dataLength);
        for (uint index = 0; index < dataLength; index++) {
            uint ind = startPos + index;
          (bytes32 typeName, address owner, uint256 created) = specificIssuerData.getTypInfoByIndex(ind);
          typeNames[index] = typeName;
          owners[index] = owner;
          createds[index] = created;
        }
        return (typeNames, owners, createds);
    }

    function removeIssuerType(bytes32 typeName) public {
        uint result = specificIssuerData.removeIssuerType(typeName);
        emit SpecificIssuerRetLog(OPERATION_REMOVE, result, typeName, address(0));
    }

    function getIssuerTypeCount()
        public
        view
        returns (uint)
    {
        return specificIssuerData.getTypeNameSize();
    }
}