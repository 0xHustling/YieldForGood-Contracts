// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.21;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract SVGImages {
    uint256 private constant MAX_IMAGES = 3;

    string[] private images;

    constructor() {
        images = new string[](MAX_IMAGES);
    }

    /**
     * @dev Returns a random SVG image.
     */
    function getSvgImage(uint256 index) public view returns (string memory) {
        return images[index];
    }

    function addImage(string memory image, uint256 index) public {
        images[index] = image;
    }

    /**
     * @dev Returns a random number between 0 and 3.
     */
    // @TODO: Replace this with a Chainlink VRF call.
    function getRandomNumber() public view returns (uint256) {
        return uint256(block.prevrandao % MAX_IMAGES);
    }
}
