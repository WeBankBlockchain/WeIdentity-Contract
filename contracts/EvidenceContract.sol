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
contract EvidenceContract {

    //Evidence struct
    struct Evidence {
        address signer;
        string sig;
        string log;
        uint256 updated;
        mapping(string => string) extra;
    }
    // Evidence hash => Evidence
    mapping(bytes32 => Evidence) evidences;
    // extra id => Evidence hash
    mapping(string => bytes32) extraKeyMapping;


    // Evidence attribute change event including signature and logs
    event EvidenceAttributeChanged(
        bytes32 hash,
        address signer,
        string sig,
        string log,
        uint256 updated
    );

    event CreateEvidence(
        bytes32 hash,
        address signer,
        string sig,
        string log,
        uint256 updated
    );

    // Additional Evidence attribute change event
    event EvidenceExtraAttributeChanged(
        bytes32 hash,
        address signer,
        string key,
        string value,
        uint256 updated
    );

    /**
     * Create evidence. Here, hash value is the key; signature and log are values. 
     * This will only create a new evidence if its hash does not exist.
     */
    function createEvidence(
        bytes32[] memory hash,
        address[] memory signer,
        string[] memory sigs,
        string[] memory logs,
        uint256[] memory updated
    )
        public
    {
        uint256 sigSize = hash.length;
        for (uint256 i = 0; i < sigSize; i++) {
            Evidence storage evidence = evidences[hash[i]];
            if (!isHashExist(hash[i])) {
                evidence.sig = sigs[i];
                evidence.log = logs[i];
                evidence.signer = signer[i];
                evidence.updated = updated[i];
                emit CreateEvidence(hash[i], signer[i], sigs[i], logs[i], updated[i]);
            }
        }
    }

    /**
     * Add signature and logs to an existing evidence. Here, hash value is the key; signature and log are values. 
     */
    function addSignatureAndLogs(
        bytes32[] memory hash,
        address[] memory signer,
        string[] memory sigs,
        string[] memory logs,
        uint256[] memory updated
    )
        public
    {
        uint256 sigSize = hash.length;
        for (uint256 i = 0; i < sigSize; i++) {
            Evidence storage evidence = evidences[hash[i]];
            if (isHashExist(hash[i])) {
                evidence.sig = sigs[i];
                evidence.log = logs[i];
                evidence.signer = signer[i];
                evidence.updated = updated[i];
                emit EvidenceAttributeChanged(hash[i], signer[i], sigs[i], logs[i], updated[i]);
            }
        }
    }

    /**
     * Create evidence by extra key. As in the normal createEvidence case, this further allocates
     * each evidence with an extra key in String format which caller can fetch as key,
     * to obtain the detailed info from within.
     * This will only create a new evidence if its hash does not exist.
     */
    function createEvidenceWithExtraKey(
        bytes32[] memory hash,
        address[] memory signer,
        string[] memory sigs,
        string[] memory logs,
        uint256[] memory updated,
        string[] memory extraKey
    )
        public
    {
        uint256 sigSize = hash.length;
        for (uint256 i = 0; i < sigSize; i++) {
            Evidence storage evidence = evidences[hash[i]];
            if (!isHashExist(hash[i])) {
                evidence.sig = sigs[i];
                evidence.log = logs[i];
                evidence.signer = signer[i];
                evidence.updated = updated[i];
                if (!isEqualString(extraKey[i], "")) {
                    extraKeyMapping[extraKey[i]] = hash[i];
                }
                emit CreateEvidence(hash[i], signer[i], sigs[i], logs[i], updated[i]);
            }
        }
    }

    /**
     * Create evidence by extra key. As in the normal createEvidence case, this further allocates
     * each evidence with an extra key in String format which caller can fetch as key,
     * to obtain the detailed info from within. This will only emit creation events when an evidence exists.
     */
    function addSignatureAndLogsWithExtraKey(
        bytes32[] memory hash,
        address[] memory signer,
        string[] memory sigs,
        string[] memory logs,
        uint256[] memory updated,
        string[] memory extraKey
    )
        public
    {
        uint256 sigSize = hash.length;
        for (uint256 i = 0; i < sigSize; i++) {
            Evidence storage evidence = evidences[hash[i]];
            if (isHashExist(hash[i])) {
                evidence.sig = sigs[i];
                evidence.log = logs[i];
                evidence.signer = signer[i];
                evidence.updated = updated[i];
                if (!isEqualString(extraKey[i], "")) {
                    extraKeyMapping[extraKey[i]] = hash[i];
                }
                emit EvidenceAttributeChanged(hash[i], signer[i], sigs[i], logs[i], updated[i]);
            }
        }
    }

    /**
     * Set arbitrary extra attributes to any EXISTING evidence.
     */
    function setAttribute(
        bytes32[] memory hash,
        address[] memory signer,
        string[] memory key,
        string[] memory value,
        uint256[] memory updated
    )
        public
    {
        uint256 sigSize = hash.length;
        for (uint256 i = 0; i < sigSize; i++) {
            if (isHashExist(hash[i])) {
                Evidence storage evidence = evidences[hash[i]];
                evidence.extra[key[i]] = value[i];
                evidence.signer = signer[i];
                evidence.updated = updated[i];
                emit EvidenceExtraAttributeChanged(hash[i], signer[i], key[i], value[i], updated[i]);
            }
        }
    }

    function getAttribute(
        bytes32 hash,
        string memory key
    )
        public
        view
        returns (string memory)
    {
        return evidences[hash].extra[key];
    }

    function getEvidence(
        bytes32 hash
    )
        public
        view
        returns (address signer, string memory sig, string memory log, uint256 updated)
    {
        require(isHashExist(hash), "require evidence not exist");
        return (evidences[hash].signer, evidences[hash].sig, evidences[hash].log, evidences[hash].updated);
    }

    function isHashExist(bytes32 hash) public view returns (bool) {
        if (evidences[hash].signer != address(0)) {
            return true;
        }
        return false;
    }

    function getHashByExtraKey(
        string memory extraKey
    )
        public
        view
        returns (bytes32)
    {
        return extraKeyMapping[extraKey];
    }

    function isEqualString(string memory a, string memory b) private pure returns (bool) {	
        if (bytes(a).length != bytes(b).length) {	
            return false;	
        } else {	
            return keccak256(abi.encode(a)) == keccak256(abi.encode(b));	
        }	
    }
}