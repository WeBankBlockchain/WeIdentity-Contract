pragma solidity ^0.4.4;
/*
 *       Copyright© (2018-2020) WeBank Co., Ltd.
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

contract EvidenceContract {

    // block number map, hash as key
    mapping(string => uint256) changed;

    // Attribute keys
    string constant private ATTRIB_KEY_SIGNINFO = "info";
    string constant private ATTRIB_KEY_EXTRA = "extra";

    // string constant private EVIDENCE_REVOKE = "revoked";

    // Error codes
    uint256 constant private RETURN_CODE_SUCCESS = 0;
    uint256 constant private RETURN_CODE_FAILURE_NOT_EXIST = 500600;
    uint256 constant private RETURN_CODE_FAILURE_NO_PERMISSION = 500000;

    // Both hash and signer are used as identification key
    event EvidenceAttributeChanged(
        string indexed hash,
        address signer,
        string key,
        string value,
        uint256 updated,
        uint256 previousBlock
    );

    function getLatestRelatedBlock(
        string hash
    ) 
        public 
        constant 
        returns (uint256) 
    {
        return changed[hash];
    }

    /**
     * Create evidence. Here, hash value is the key; signInfo is the base64 signature;
     * and extra is the compact json of blob: {"credentialId":"aacc1122-324b.."}
     * This allows append operation from other signer onto a same hash, so no permission check.
     */
    function createEvidence(
        string hash,
        string sig,
        string extra,
        uint256 updated
    )
        public
    {
        EvidenceAttributeChanged(hash, msg.sender, ATTRIB_KEY_SIGNINFO, sig, updated, changed[hash]);
        EvidenceAttributeChanged(hash, msg.sender, ATTRIB_KEY_EXTRA, extra, updated, changed[hash]);
        changed[hash] = block.number;
    }

    /**
     * Aribitrarily append attributes to an existing hash evidence, e.g. revoke status.
     */
    function setAttribute(
        string hash,
        string key,
        string value,
        uint256 updated
    )
        public
    {
        if (!isHashExist(hash)) {
            return;
        }
        if (isEqualString(key, ATTRIB_KEY_SIGNINFO)) {
            return;
        }
        EvidenceAttributeChanged(hash, msg.sender, key, value, updated, changed[hash]);
        changed[hash] = block.number;
    }

    function isHashExist(string hash) public constant returns (bool) {
        if (changed[hash] != 0) {
            return true;
        }
        return false;
    }

    function isEqualString(string a, string b) public constant returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(a) == keccak256(b);
        }
    }
}