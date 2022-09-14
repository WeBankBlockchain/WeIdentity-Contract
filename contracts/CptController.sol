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

import "./CptData.sol";
import "./WeIdContract.sol";
import "./RoleController.sol";

contract CptController {

    // Error codes
    uint private CPT_NOT_EXIST = 500301;
    uint private AUTHORITY_ISSUER_CPT_ID_EXCEED_MAX = 500302;
    uint private CPT_PUBLISHER_NOT_EXIST = 500303;
    uint private CPT_ALREADY_EXIST = 500304;
    uint private NO_PERMISSION = 500305;

    // Default CPT version
    int private CPT_DEFAULT_VERSION = 1;

    WeIdContract private weIdContract;
    RoleController private roleController;

    // Reserved for contract owner check
    address private internalRoleControllerAddress;
    address private owner;

    // CPT and Policy data storage address separately
    address private cptDataStorageAddress;
    address private policyDataStorageAddress;

    constructor(
        address cptDataAddress,
        address weIdContractAddress
    ) 
        public
    {
        owner = msg.sender;
        weIdContract = WeIdContract(weIdContractAddress);
        cptDataStorageAddress = cptDataAddress;
    }

    function setPolicyData(
        address policyDataAddress
    )
        public
    {
        if (msg.sender != owner || policyDataAddress == address(0)) {
            return;
        }
        policyDataStorageAddress = policyDataAddress;
    }

    function setRoleController(
        address roleControllerAddress
    )
        public
    {
        if (msg.sender != owner || roleControllerAddress == address(0)) {
            return;
        }
        roleController = RoleController(roleControllerAddress);
        if (roleController.ROLE_ADMIN() <= 0) {
            return;
        }
        internalRoleControllerAddress = roleControllerAddress;
    }

    event RegisterCptRetLog(
        uint retCode, 
        uint cptId, 
        int cptVersion
    );

    event UpdateCptRetLog(
        uint retCode, 
        uint cptId, 
        int cptVersion
    );

    function registerCptInner(
        uint cptId,
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s,
        address dataStorageAddress
    )
        private
        returns (bool)
    {
        if (!weIdContract.isIdentityExist(publisher)) {
            emit RegisterCptRetLog(CPT_PUBLISHER_NOT_EXIST, 0, 0);
            return false;
        }
        CptData cptData = CptData(dataStorageAddress);
        if (cptData.isCptExist(cptId)) {
            emit RegisterCptRetLog(CPT_ALREADY_EXIST, cptId, 0);
            return false;
        }

        // Authority related checks. We use tx.origin here to decide the authority. For SDK
        // calls, publisher and tx.origin are normally the same. For DApp calls, tx.origin dictates.
        uint lowId = cptData.AUTHORITY_ISSUER_START_ID();
        uint highId = cptData.NONE_AUTHORITY_ISSUER_START_ID();
        if (cptId < lowId) {
            // Only committee member can create this, check initialization first
            if (internalRoleControllerAddress == address(0)) {
                emit RegisterCptRetLog(NO_PERMISSION, cptId, 0);
                return false;
            }
            if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())) {
                emit RegisterCptRetLog(NO_PERMISSION, cptId, 0);
                return false;
            }
        } else if (cptId < highId) {
            // Only authority issuer can create this, check initialization first
            if (internalRoleControllerAddress == address(0)) {
                emit RegisterCptRetLog(NO_PERMISSION, cptId, 0);
                return false;
            }
            if (!roleController.checkPermission(tx.origin, roleController.MODIFY_KEY_CPT())) {
                emit RegisterCptRetLog(NO_PERMISSION, cptId, 0);
                return false;
            }
        }

        intArray[0] = CPT_DEFAULT_VERSION;
        cptData.putCpt(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s);

        emit RegisterCptRetLog(0, cptId, CPT_DEFAULT_VERSION);
        return true;
    }

    function registerCpt(
        uint cptId,
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        return registerCptInner(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, cptDataStorageAddress);
    }

    function registerPolicy(
        uint cptId,
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        return registerCptInner(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, policyDataStorageAddress);
    }

    function registerCptInner(
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s,
        address dataStorageAddress
    ) 
        private 
        returns (bool) 
    {
        if (!weIdContract.isIdentityExist(publisher)) {
            emit RegisterCptRetLog(CPT_PUBLISHER_NOT_EXIST, 0, 0);
            return false;
        }
        CptData cptData = CptData(dataStorageAddress);

        uint cptId = cptData.getCptId(publisher); 
        if (cptId == 0) {
            emit RegisterCptRetLog(AUTHORITY_ISSUER_CPT_ID_EXCEED_MAX, 0, 0);
            return false;
        }
        int cptVersion = CPT_DEFAULT_VERSION;
        intArray[0] = cptVersion;
        cptData.putCpt(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s);

        emit RegisterCptRetLog(0, cptId, cptVersion);
        return true;
    }

    function registerCpt(
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        public 
        returns (bool) 
    {
        return registerCptInner(publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, cptDataStorageAddress);
    }

    function registerPolicy(
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) 
        public 
        returns (bool) 
    {
        return registerCptInner(publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, policyDataStorageAddress);
    }

    function updateCptInner(
        uint cptId, 
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s,
        address dataStorageAddress
    ) 
        private 
        returns (bool) 
    {
        if (!weIdContract.isIdentityExist(publisher)) {
            emit UpdateCptRetLog(CPT_PUBLISHER_NOT_EXIST, 0, 0);
            return false;
        }
        CptData cptData = CptData(dataStorageAddress);
        if (!roleController.checkPermission(tx.origin, roleController.MODIFY_AUTHORITY_ISSUER())
            && publisher != cptData.getCptPublisher(cptId)) {
            emit UpdateCptRetLog(NO_PERMISSION, 0, 0);
            return false;
        }
        if (cptData.isCptExist(cptId)) {
            int[8] memory cptIntArray = cptData.getCptIntArray(cptId);
            int cptVersion = cptIntArray[0] + 1;
            intArray[0] = cptVersion;
            int created = cptIntArray[1];
            intArray[1] = created;
            cptData.putCpt(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s);
            emit UpdateCptRetLog(0, cptId, cptVersion);
            return true;
        } else {
            emit UpdateCptRetLog(CPT_NOT_EXIST, 0, 0);
            return false;
        }
    }

    function updateCpt(
        uint cptId, 
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        return updateCptInner(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, cptDataStorageAddress);
    }

    function updatePolicy(
        uint cptId, 
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    )
        public
        returns (bool)
    {
        return updateCptInner(cptId, publisher, intArray, bytes32Array, jsonSchemaArray, v, r, s, policyDataStorageAddress);
    }

    function queryCptInner(
        uint cptId,
        address dataStorageAddress
    ) 
        private 
        view 
        returns (
        address publisher, 
        int[] memory intArray, 
        bytes32[] memory bytes32Array,
        bytes32[] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s)
    {
        CptData cptData = CptData(dataStorageAddress);
        publisher = cptData.getCptPublisher(cptId);
        intArray = getCptDynamicIntArray(cptId, dataStorageAddress);
        bytes32Array = getCptDynamicBytes32Array(cptId, dataStorageAddress);
        jsonSchemaArray = getCptDynamicJsonSchemaArray(cptId, dataStorageAddress);
        (v, r, s) = cptData.getCptSignature(cptId);
    }

    function queryCpt(
        uint cptId
    ) 
        public 
        view 
        returns 
    (
        address publisher, 
        int[] memory intArray, 
        bytes32[] memory bytes32Array,
        bytes32[] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s)
    {
        return queryCptInner(cptId, cptDataStorageAddress);
    }

    function queryPolicy(
        uint cptId
    ) 
        public 
        view 
        returns 
    (
        address publisher, 
        int[] memory intArray, 
        bytes32[] memory bytes32Array,
        bytes32[] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s)
    {
        return queryCptInner(cptId, policyDataStorageAddress);
    }

    function getCptDynamicIntArray(
        uint cptId,
        address dataStorageAddress
    ) 
        public
        view
        returns (int[] memory)
    {
        CptData cptData = CptData(dataStorageAddress);
        int[8] memory staticIntArray = cptData.getCptIntArray(cptId);
        int[] memory dynamicIntArray = new int[](8);
        for (uint i = 0; i < 8; i++) {
            dynamicIntArray[i] = staticIntArray[i];
        }
        return dynamicIntArray;
    }

    function getCptDynamicBytes32Array(
        uint cptId,
        address dataStorageAddress
    ) 
        public
        view
        returns (bytes32[] memory)
    {
        CptData cptData = CptData(dataStorageAddress);
        bytes32[8] memory staticBytes32Array = cptData.getCptBytes32Array(cptId);
        bytes32[] memory dynamicBytes32Array = new bytes32[](8);
        for (uint i = 0; i < 8; i++) {
            dynamicBytes32Array[i] = staticBytes32Array[i];
        }
        return dynamicBytes32Array;
    }

    function getCptDynamicJsonSchemaArray(
        uint cptId,
        address dataStorageAddress
    ) 
        public
        view
        returns (bytes32[] memory)
    {
        CptData cptData = CptData(dataStorageAddress);
        bytes32[128] memory staticBytes32Array = cptData.getCptJsonSchemaArray(cptId);
        bytes32[] memory dynamicBytes32Array = new bytes32[](128);
        for (uint i = 0; i < 128; i++) {
            dynamicBytes32Array[i] = staticBytes32Array[i];
        }
        return dynamicBytes32Array;
    }

    function getPolicyIdList(uint startPos, uint num)
        public
        view
        returns (uint[] memory)
    {
        CptData cptData = CptData(policyDataStorageAddress);
        uint totalLength = cptData.getDatasetLength();
        uint dataLength;
        if (totalLength < startPos) {
            return new uint[](1);
        } else if (totalLength <= startPos + num) {
            dataLength = totalLength - startPos;
        } else {
            dataLength = num;
        }
        uint[] memory result = new uint[](dataLength);
        for (uint i = 0; i < dataLength; i++) {
            result[i] = cptData.getCptIdFromIndex(startPos + i);
        }
        return result;
    }

    function getCptIdList(uint startPos, uint num)
        public
        view
        returns (uint[] memory)
    {
        CptData cptData = CptData(cptDataStorageAddress);
        uint totalLength = cptData.getDatasetLength();
        uint dataLength;
        if (totalLength < startPos) {
            return new uint[](1);
        } else if (totalLength <= startPos + num) {
            dataLength = totalLength - startPos;
        } else {
            dataLength = num;
        }
        uint[] memory result = new uint[](dataLength);
        for (uint i = 0; i < dataLength; i++) {
            result[i] = cptData.getCptIdFromIndex(startPos + i);
        }
        return result;
    }

    function getTotalCptId() public view returns (uint) {
        CptData cptData = CptData(cptDataStorageAddress);
        return cptData.getDatasetLength();
    }

    function getTotalPolicyId() public view returns (uint) {
        CptData cptData = CptData(policyDataStorageAddress);
        return cptData.getDatasetLength();
    }

    // --------------------------------------------------------
    // Credential Template storage related funcs
    // store the cptId and blocknumber
    mapping (uint => uint) credentialTemplateStored;
    event CredentialTemplate(
        uint cptId,
        bytes credentialPublicKey,
        bytes credentialProof
    );

    function putCredentialTemplate(
        uint cptId,
        bytes memory credentialPublicKey,
        bytes memory credentialProof
    )
        public
    {
        emit CredentialTemplate(cptId, credentialPublicKey, credentialProof);
        credentialTemplateStored[cptId] = block.number;
    }

    function getCredentialTemplateBlock(
        uint cptId
    )
        public
        view
        returns(uint)
    {
        return credentialTemplateStored[cptId];
    }

    // --------------------------------------------------------
    // Claim Policy storage belonging to v.s. Presentation, Publisher WeID, and CPT
    // Store the registered Presentation Policy ID (uint) v.s. Claim Policy ID list (uint[])
    mapping (uint => uint[]) private claimPoliciesFromPresentation;
    mapping (uint => address) private claimPoliciesWeIdFromPresentation;
    // Store the registered CPT ID (uint) v.s. Claim Policy ID list (uint[])
    mapping (uint => uint[]) private claimPoliciesFromCPT;

    uint private presentationClaimMapId = 1;

    function putClaimPoliciesIntoPresentationMap(uint[] memory uintArray) public {
        claimPoliciesFromPresentation[presentationClaimMapId] = uintArray;
        claimPoliciesWeIdFromPresentation[presentationClaimMapId] = msg.sender;
        emit RegisterCptRetLog(0, presentationClaimMapId, CPT_DEFAULT_VERSION);
        presentationClaimMapId ++;
    }

    function getClaimPoliciesFromPresentationMap(uint presentationId) public view returns (uint[] memory, address) {
        return (claimPoliciesFromPresentation[presentationId], claimPoliciesWeIdFromPresentation[presentationId]);
    }
    
    function putClaimPoliciesIntoCptMap(uint cptId, uint[] memory uintArray) public {
        claimPoliciesFromCPT[cptId] = uintArray;
        emit RegisterCptRetLog(0, cptId, CPT_DEFAULT_VERSION);
    }
    
    function getClaimPoliciesFromCptMap(uint cptId) public view returns (uint[] memory) {
        return claimPoliciesFromCPT[cptId];
    }
}