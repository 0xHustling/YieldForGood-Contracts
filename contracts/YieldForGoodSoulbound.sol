// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "base64-sol/base64.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { ERC5192 } from "./ERC5192.sol";
import { SVGImages } from "./SVGImages.sol";
import { IYieldForGoodSoulBound } from "./interfaces/IYieldForGoodSoulBound.sol";

/**
 * @title YieldForGood Soulbound NFT
 * @dev Yield For Good Soulbound NFT is minted to anyone who stakes in the YieldForGood contract.
 */
contract YieldForGoodSoulBound is IYieldForGoodSoulBound, ERC5192, Ownable {
    uint256 public lastTokenId;
    address public yfgAddress;

    mapping(uint256 tokenId => uint256 svgIndex) private tokenIdToSvgIndex;

    string private constant baseURI = "data:image/svg+xml;base64,";

    SVGImages SvgLib;

    /**
     * @dev Constructor to initialize the YieldForGood Soulbound contract.
     * @param name The name of the Soulbound NFT
     * @param symbol The symbol of the Soulbound NFT
     */
    constructor(
        string memory name,
        string memory symbol,
        SVGImages svgLib
    ) ERC5192(name, symbol, true) Ownable(msg.sender) {
        SvgLib = svgLib;
    }

    /**
     * @dev Sets the YFG  contract.
     * @param _yfgAddress The address of the YGF Soulbound.
     */
    function setYFG(address _yfgAddress) external onlyOwner {
        yfgAddress = _yfgAddress;
    }

    function _baseURI() internal pure override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {ERC721-mint}.
     */
    function mint(address to) public {
        if (msg.sender != address(yfgAddress)) {
            revert UnauthorizedMint();
        }

        uint256 tokenId = ++lastTokenId;
        _safeMint(to, tokenId);

        uint256 svgIndex = SvgLib.getRandomNumber();
        tokenIdToSvgIndex[tokenId] = svgIndex;
    }

    /**
     * @dev Converts an SVG string to an image URI.
     * @param svg The SVG string to convert to an image URI
     */
    function svgToImageURI(string memory svg) public pure returns (string memory) {
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURI, svgBase64Encoded));
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        uint256 svgIndex = tokenIdToSvgIndex[tokenId];
        return formatTokenURI(SvgLib.getSvgImage(svgIndex));
    }

    /**
     * @dev Formats the token URI
     * @param imageURI The image URI to be used for the Soulbound NFT
     */
    function formatTokenURI(string memory imageURI) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(),
                                '", "description":"Yield for Good Proof of Contribution", "attributes":"", "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
