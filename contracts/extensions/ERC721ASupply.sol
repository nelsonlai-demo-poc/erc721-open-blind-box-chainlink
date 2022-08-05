//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ERC721ASupply is Ownable {
    /** @dev maximum supply of the project
     *  @dev CANNOT be changed after the contract is deployed
     */
    uint256 public maxSupply;
    /** @dev supply limit now
     *  @dev CANNOT greater than maxSupply
     *  @dev CAN be changed after the contract is deployed
     */
    uint256 public supplyLimit;

    constructor(uint256 _maxSupply, uint256 _supplyLimit) {
        maxSupply = _maxSupply;
        supplyLimit = _supplyLimit;
    }

    //// Write Functions ////

    /** @dev update supply limit
     */
    function setSupplyLimit(uint256 _supplyLimit) public onlyOwner {
        if (_supplyLimit > maxSupply) {
            revert SupplyLimitGreaterThanMaxSupply();
        }
        supplyLimit = _supplyLimit;
    }

    //// Errors ////
    error SupplyLimitGreaterThanMaxSupply();
}
