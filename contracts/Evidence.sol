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

contract Evidence {
    bytes32[] private dataHash;
    address[] private signer;
    bytes32[] private r;
    bytes32[] private s;
    uint8[] private v;
    bytes32[] private extraContent;

    // Event and Constants.
    uint private RETURN_CODE_SUCCESS = 0;
    uint private RETURN_CODE_FAILURE_ILLEGAL_INPUT = 500401;
    event AddSignatureLog(uint retCode, address signer, bytes32 r, bytes32 s, uint8 v);
    event AddExtraContentLog(uint retCode, address sender, bytes32 extraContent);
    event AddHashLog(uint retCode, address signer);

    constructor(
        bytes32[] memory hashValue,
        address[] memory signerValue,
        bytes32 rValue,
        bytes32 sValue,
        uint8 vValue,
        bytes32[] memory extraValue
    )
        public
    {
        uint numOfHashParts = hashValue.length;
        uint index;
        for (index = 0; index < numOfHashParts; index++) {
            if (hashValue[index] != bytes32(0)) {
                dataHash.push(hashValue[index]);
            }
        }
        uint numOfSigners = signerValue.length;
        for (index = 0; index < numOfSigners; index++) {
            signer.push(signerValue[index]);
        }
        // Init signature fields - should always be of the same size as signer array
        for (index = 0; index < numOfSigners; index++) {
            if (tx.origin == signer[index]) {
                r.push(rValue);
                s.push(sValue);
                v.push(vValue);
            } else {
                r.push(bytes32(0));
                s.push(bytes32(0));
                v.push(uint8(0));
            }
        }
        uint numOfExtraValue = extraValue.length;
        for (index = 0; index < numOfExtraValue; index++) {
            extraContent.push(extraValue[index]);
        }
    }

    function getInfo() public view returns (
        bytes32[] memory hashValue,
        address[] memory signerValue,
        bytes32[] memory rValue,
        bytes32[] memory sValue,
        uint8[] memory vValue,
        bytes32[] memory extraValue
    )
    {
        uint numOfHashParts = dataHash.length;
        uint index;
        hashValue = new bytes32[](numOfHashParts);
        for (index = 0; index < numOfHashParts; index++) {
            hashValue[index] = dataHash[index];
        }
        uint numOfSigners = signer.length;
        signerValue = new address[](numOfSigners);
        for (index = 0; index < numOfSigners; index++) {
            signerValue[index] = signer[index];
        }
        uint numOfSignatures = r.length;
        rValue = new bytes32[](numOfSignatures);
        sValue = new bytes32[](numOfSignatures);
        vValue = new uint8[](numOfSignatures);
        for (index = 0; index < numOfSignatures; index++) {
            rValue[index] = r[index];
            sValue[index] = s[index];
            vValue[index] = v[index];
        }
        uint numOfExtraValue = extraContent.length;
        extraValue = new bytes32[](numOfExtraValue);
        for (index = 0; index < numOfExtraValue; index++) {
            extraValue[index] = extraContent[index];
        }
        return (hashValue, signerValue, rValue, sValue, vValue, extraValue);
    }

    function addSignature(
        bytes32 rValue,
        bytes32 sValue,
        uint8 vValue
    )
        public
        returns (bool)
    {
        uint numOfSigners = signer.length;
        for (uint index = 0; index < numOfSigners; index++) {
            if (tx.origin == signer[index] && v[index] == uint8(0)) {
                r[index] = rValue;
                s[index] = sValue;
                v[index] = vValue;
                emit AddSignatureLog(RETURN_CODE_SUCCESS, tx.origin, rValue, sValue, vValue);
                return true;
            }
        }
        emit AddSignatureLog(RETURN_CODE_FAILURE_ILLEGAL_INPUT, tx.origin, rValue, sValue, vValue);
        return false;
    }

    function setHash(bytes32[] memory hashArray) public {
        uint numOfSigners = signer.length;
        for (uint index = 0; index < numOfSigners; index++) {
            if (tx.origin == signer[index]) {
                dataHash = new bytes32[](hashArray.length);
                for (uint i = 0; i < hashArray.length; i++) {
                    dataHash[i] = hashArray[i];
                }
                emit AddHashLog(RETURN_CODE_SUCCESS, tx.origin);
                return;
            }
        }
        emit AddHashLog(RETURN_CODE_FAILURE_ILLEGAL_INPUT, tx.origin);
        return;
    }

    function addExtraValue(bytes32 extraValue) public returns (bool) {
        uint numOfSigners = signer.length;
        for (uint index = 0; index < numOfSigners; index++) {
            if (tx.origin == signer[index]) {
                extraContent.push(extraValue);
                emit AddExtraContentLog(RETURN_CODE_SUCCESS, tx.origin, extraValue);
                return true;
            }
        }
        emit AddExtraContentLog(RETURN_CODE_FAILURE_ILLEGAL_INPUT, tx.origin, extraValue);
        return false;
    }
}
