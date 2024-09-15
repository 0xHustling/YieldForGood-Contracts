// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IYieldForGoodSoulBound {
    /**
     * @dev Emitted when the contract is trying to mint a Soulbound NFT without permission.
     */
    error UnauthorizedMint();

    function mint(address to) external;
}
