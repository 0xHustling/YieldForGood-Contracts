// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC5192 } from "./interfaces/IERC5192.sol";

abstract contract ERC5192 is ERC721URIStorage, ERC721Enumerable, IERC5192 {
    bool private _locked;

    error TransferLocked();

    constructor(string memory name, string memory symbol, bool isLocked) ERC721(name, symbol) {
        _locked = isLocked;
    }

    function locked(uint256 tokenId) external view virtual returns (bool) {
        _requireOwned(tokenId);
        return _locked;
    }

    function _checkLockStatus() private view {
        if (_locked) revert TransferLocked();
    }

    function approve(address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        _checkLockStatus();
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override(ERC721, IERC721) {
        _checkLockStatus();
        super.setApprovalForAll(operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, IERC721) {
        _checkLockStatus();
        super.transferFrom(from, to, tokenId);
    }

    function ownedTokens(address ownerAddress) external view returns (uint256[] memory) {
        uint256 tokenBalance = balanceOf(ownerAddress);
        uint256[] memory tokens = new uint256[](tokenBalance);

        for (uint256 i = 0; i < tokenBalance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(ownerAddress, i);
            tokens[i] = tokenId;
        }

        return tokens;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override(ERC721, IERC721) {
        _checkLockStatus();
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return
            interfaceId == type(ERC721Enumerable).interfaceId ||
            interfaceId == type(ERC721URIStorage).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC165-_increaseBalance}.
     */
    function _increaseBalance(address account, uint128 amount) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }

    /**
     * @dev See {IERC165-_update}.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev See {IERC165-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
