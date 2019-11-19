pragma solidity ^0.4.4;
/*
 *       Copyright© (2018) WeBank Co., Ltd.
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

contract WeIdAuthorize {

    // Alternate account related functions
    mapping(address => mapping(address => bool)) alternate;
    mapping(address => bool) selfRevoked;

    uint constant private WEID_AUTHORIZE_ADD = 0;
    uint constant private WEID_AUTHORIZE_REVOKE = 1;

    event WeIdAlternate(
        uint operation,
        address sender,
        address original,
        address candidate,
        uint currentBlock
    );

    /**
     * Add an alternate - candidate address - to the original address.
     */
    function addAlternate(address original, address candidate) public {
        if (!isAlternateValid(original, msg.sender) || candidate == 0x0) {
            return;
        }
        // Actual adding function
        if (original == candidate) {
            selfRevoked[original] = true;
        } else {
            alternate[original][candidate] = true;
        }
        WeIdAlternate(WEID_AUTHORIZE_ADD, msg.sender, original, candidate, block.number);
    }

    /**
     * Revoke an alternate - candidate address - from the original address.
     * WARN: this could possibly remove the last available alternate. Be careful!
     */
    function revokeAlternate(address original, address candidate) public {
        if (!isAlternateValid(original, msg.sender) || candidate == 0x0) {
            return;
        }
        // Actual adding function
        if (original == candidate) {
            selfRevoked[original] = false;
        } else {
            alternate[original][candidate] = false;
        }
        WeIdAlternate(WEID_AUTHORIZE_REVOKE, msg.sender, original, candidate, block.number);
    }

    /**
     * Check whether the candidate address is an alternate of the original address.
     */
    function isAlternateValid(address original, address candidate) public constant returns (bool) {
        if (original == candidate && selfRevoked[original] == true) {
            return false;
        }
        if (original != candidate && alternate[original][candidate] == false) {
            return false;
        }
        if (0x0 == original || 0x0 == candidate) {
            return false;
        }
        return true;
    }
}