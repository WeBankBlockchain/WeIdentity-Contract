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

import "./Evidence.sol";

 /**
 * @title EvidenceFactory
 * Evidence factory contract, also support evidence address lookup service.
 */

contract EvidenceFactory {
    Evidence private evidence;

    // Event and Constants.
    uint private RETURN_CODE_SUCCESS = 0;
    uint private RETURN_CODE_FAILURE_ILLEGAL_INPUT = 500401;

    event CreateEvidenceLog(uint retCode, address addr);
    event PutEvidenceLog(uint retCode, address addr);

    mapping (bytes32 => address) private evidenceMappingPre;
    mapping (bytes32 => address) private evidenceMappingAfter;

    function createEvidence(
        bytes32[] memory dataHash,
        address[] memory signer,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes32[] memory extra
    )
        public
    {
        uint numOfSigners = signer.length;
        for (uint index = 0; index < numOfSigners; index++) {
            if (signer[index] == address(0)) {
                emit CreateEvidenceLog(RETURN_CODE_FAILURE_ILLEGAL_INPUT, address(0));
            }
        }
        Evidence evidence = new Evidence(dataHash, signer, r, s, v, extra);
        emit CreateEvidenceLog(RETURN_CODE_SUCCESS, address(evidence));
    }
    
    function putEvidence(bytes32[] memory hashValue, address addr) public returns (bool) {
        if (hashValue.length < 2 || addr == address(0)) {
            emit PutEvidenceLog(RETURN_CODE_FAILURE_ILLEGAL_INPUT, addr);
            return false;
        }
        evidenceMappingPre[hashValue[0]] = addr;
        evidenceMappingAfter[hashValue[1]] = addr;
        emit PutEvidenceLog(RETURN_CODE_SUCCESS, addr);
        return true;
    }

    function getEvidence(bytes32[] memory hashValue) public view returns (address) {
        if (hashValue.length < 2) {
            return address(0);
        }
        address addr = evidenceMappingPre[hashValue[0]];
        if (addr == evidenceMappingAfter[hashValue[1]]) {
            return addr;
        }
        return address(0);
    }
}