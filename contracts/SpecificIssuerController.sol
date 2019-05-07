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
    uint constant private OPERATION_ADD = 0;
    uint constant private OPERATION_REMOVE = 1;
    uint constant private RETURN_CODE_SUCCESS = 0;
    uint constant private RETURN_CODE_FAILURE_ALREADY_EXISTS = 500501;
    uint constant private RETURN_CODE_FAILURE_NOT_EXIST = 500502;
    uint constant private RETURN_CODE_FAILURE_NO_PERMISSION = 500503;

    event SpecificIssuerRetLog(uint operation, uint retCode, bytes32 typeName, address addr);

    // Constructor.
    function SpecificIssuerController(
        address specificIssuerDataAddress,
        address roleControllerAddress
    )
        public
    {
        specificIssuerData = SpecificIssuerData(specificIssuerDataAddress);
        roleController = RoleController(roleControllerAddress);
    }

    function registerIssuerType(bytes32 typeName) public {
        bool result = specificIssuerData.registerIssuerType(typeName);
        if (!result) {
            SpecificIssuerRetLog(OPERATION_ADD, RETURN_CODE_FAILURE_ALREADY_EXISTS, typeName, 0x0);
        } else {
            SpecificIssuerRetLog(OPERATION_ADD, RETURN_CODE_SUCCESS, typeName, 0x0);
        }
    }

    function isIssuerTypeExist(bytes32 typeName) public constant returns (bool) {
        return specificIssuerData.isIssuerTypeExist(typeName);
    }

    function addIssuer(bytes32 typeName, address addr) public {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
            SpecificIssuerRetLog(OPERATION_ADD, RETURN_CODE_FAILURE_NO_PERMISSION, typeName, addr);
            return;
        }
        if (!specificIssuerData.isIssuerTypeExist(typeName)) {
            SpecificIssuerRetLog(OPERATION_ADD, RETURN_CODE_FAILURE_NOT_EXIST, typeName, addr);
        }
        bool result = specificIssuerData.addIssuer(typeName, addr);
        if (!result) {
            SpecificIssuerRetLog(OPERATION_ADD, RETURN_CODE_FAILURE_ALREADY_EXISTS, typeName, addr);
        } else {
            SpecificIssuerRetLog(OPERATION_ADD, RETURN_CODE_SUCCESS, typeName, addr);
        }
    }

    function removeIssuer(bytes32 typeName, address addr) public {
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
            SpecificIssuerRetLog(OPERATION_REMOVE, RETURN_CODE_FAILURE_NO_PERMISSION, typeName, addr);
            return;
        }
        if (!specificIssuerData.isIssuerTypeExist(typeName)) {
            SpecificIssuerRetLog(OPERATION_REMOVE, RETURN_CODE_FAILURE_NOT_EXIST, typeName, addr);
        }
        bool result = specificIssuerData.removeIssuer(typeName, addr);
        if (!result) {
            SpecificIssuerRetLog(OPERATION_REMOVE, RETURN_CODE_FAILURE_NOT_EXIST, typeName, addr);
        } else {
            SpecificIssuerRetLog(OPERATION_REMOVE, RETURN_CODE_SUCCESS, typeName, addr);
        }
    }

    function isSpecificTypeIssuer(bytes32 typeName, address addr) public constant returns (bool) {
        return specificIssuerData.isSpecificTypeIssuer(typeName, addr);
    }

    function getAllSpecificTypeIssuer(bytes32 typeName, uint startPos, uint num) public constant returns (address[]) {
        if (num == 0 || !specificIssuerData.isIssuerTypeExist(typeName)) {
            return new address[](50);
        }

        // Calculate actual dataLength via batch return for better perf
        uint totalLength = specificIssuerData.getSpecificTypeIssuerMemberLength(typeName);
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
        tempArray = specificIssuerData.getSpecificTypeIssuerMembers(typeName, startPos);
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
}