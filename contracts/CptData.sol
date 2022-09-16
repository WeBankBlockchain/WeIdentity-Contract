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
import "./AuthorityIssuerData.sol";
contract CptData {
    // CPT ID has been categorized into 3 zones: 0 - 999 are reserved for system CPTs,
    //  1000-2000000 for Authority Issuer's CPTs, and the rest for common WeIdentiy DIDs.
    uint public AUTHORITY_ISSUER_START_ID = 1000;
    uint public NONE_AUTHORITY_ISSUER_START_ID = 2000000;
    uint private authority_issuer_current_id = 1000;
    uint private none_authority_issuer_current_id = 2000000;

    AuthorityIssuerData private authorityIssuerData;

    constructor(
        address authorityIssuerDataAddress
    ) 
        public
    {
        authorityIssuerData = AuthorityIssuerData(authorityIssuerDataAddress);
    }

    struct Signature {
        uint8 v; 
        bytes32 r; 
        bytes32 s;
    }

    struct Cpt {
        //store the weid address of cpt publisher
        address publisher;
        // [0]: cpt version, [1]: created, [2]: updated, [3]: the CPT ID
        int[8] intArray;
        // [0]: desc
        bytes32[8] bytes32Array;
        //store json schema
        bytes32[128] jsonSchemaArray;
        //store signature
        Signature signature;
    }

    mapping (uint => Cpt) private cptMap;
    uint[] private cptIdList;

    function putCpt(
        uint cptId, 
        address cptPublisher, 
        int[8] memory cptIntArray, 
        bytes32[8] memory cptBytes32Array,
        bytes32[128] memory cptJsonSchemaArray, 
        uint8 cptV, 
        bytes32 cptR, 
        bytes32 cptS
    ) 
        public 
        returns (bool) 
    {
        Signature memory cptSignature = Signature({v: cptV, r: cptR, s: cptS});
        cptMap[cptId] = Cpt({publisher: cptPublisher, intArray: cptIntArray, bytes32Array: cptBytes32Array, jsonSchemaArray:cptJsonSchemaArray, signature: cptSignature});
        cptIdList.push(cptId);
        return true;
    }

    function getCptId(
        address publisher
    ) 
        public 
        returns 
        (uint cptId)
    {
        if (authorityIssuerData.isAuthorityIssuer(publisher)) {
            while (isCptExist(authority_issuer_current_id)) {
                authority_issuer_current_id++;
            }
            cptId = authority_issuer_current_id++;
            if (cptId >= NONE_AUTHORITY_ISSUER_START_ID) {
                cptId = 0;
            }
        } else {
            while (isCptExist(none_authority_issuer_current_id)) {
                none_authority_issuer_current_id++;
            }
            cptId = none_authority_issuer_current_id++;
        }
    }

    function getCpt(
        uint cptId
    ) 
        public 
        view 
        returns (
        address publisher, 
        int[8] memory intArray, 
        bytes32[8] memory bytes32Array,
        bytes32[128] memory jsonSchemaArray, 
        uint8 v, 
        bytes32 r, 
        bytes32 s) 
    {
        Cpt memory cpt = cptMap[cptId];
        publisher = cpt.publisher;
        intArray = cpt.intArray;
        bytes32Array = cpt.bytes32Array;
        jsonSchemaArray = cpt.jsonSchemaArray;
        v = cpt.signature.v;
        r = cpt.signature.r;
        s = cpt.signature.s;
    } 

    function getCptPublisher(
        uint cptId
    ) 
        public 
        view 
        returns (address publisher)
    {
        Cpt memory cpt = cptMap[cptId];
        publisher = cpt.publisher;
    }

    function getCptIntArray(
        uint cptId
    ) 
        public 
        view 
        returns (int[8] memory intArray)
    {
        Cpt memory cpt = cptMap[cptId];
        intArray = cpt.intArray;
    }

    function getCptJsonSchemaArray(
        uint cptId
    ) 
        public 
        view 
        returns (bytes32[128] memory jsonSchemaArray)
    {
        Cpt memory cpt = cptMap[cptId];
        jsonSchemaArray = cpt.jsonSchemaArray;
    }

    function getCptBytes32Array(
        uint cptId
    ) 
        public 
        view 
        returns (bytes32[8] memory bytes32Array)
    {
        Cpt memory cpt = cptMap[cptId];
        bytes32Array = cpt.bytes32Array;
    }

    function getCptSignature(
        uint cptId
    ) 
        public 
        view 
        returns (uint8 v, bytes32 r, bytes32 s) 
    {
        Cpt memory cpt = cptMap[cptId];
        v = cpt.signature.v;
        r = cpt.signature.r;
        s = cpt.signature.s;
    }

    function isCptExist(
        uint cptId
    ) 
        public 
        view 
        returns (bool)
    {
        int[8] memory intArray = getCptIntArray(cptId);
        if (intArray[0] != 0) {
            return true;
        } else {
            return false;
        }
    }

    function getDatasetLength() public view returns (uint) {
        return cptIdList.length;
    }

    function getCptIdFromIndex(uint index) public view returns (uint) {
        return cptIdList[index];
    }
}