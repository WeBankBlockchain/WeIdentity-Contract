pragma solidity ^0.4.4;
/*
 *       Copyright© (2018-2019) WeBank Co., Ltd.
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

import "./Evidence.sol";

 /**
 * @title EvidenceFactory
 * Evidence factory contract.
 */

contract EvidenceFactory {
    Evidence private evidence;

    // Event and Constants.
    uint constant private RETURN_CODE_SUCCESS = 0;
    uint constant private RETURN_CODE_FAILURE_ILLEGAL_INPUT = 500401;

    event CreateEvidenceLog(uint retCode, address addr);

    function createEvidence(
        bytes32[] dataHash,
        address[] signer,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes32[] extra
    )
        public
        returns (bool)
    {
        uint numOfSigners = signer.length;
        for (uint index = 0; index < numOfSigners; index++) {
            if (signer[index] == 0x0) {
                CreateEvidenceLog(RETURN_CODE_FAILURE_ILLEGAL_INPUT, evidence);
                return false;
            }
        }
        Evidence evidence = new Evidence(dataHash, signer, r, s, v, extra);
        CreateEvidenceLog(RETURN_CODE_SUCCESS, evidence);
        return true;
    }
}