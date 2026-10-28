// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DinoRenderer} from "./DinoRenderer.sol";

/// @title MAZE DINO
/// @notice Collectible dinos you hatch by paying MAZE. Each dino is an 8-digit DNA number and its
/// artwork is drawn fully on-chain from that number. There is no owner, no admin and no upgrade:
/// price, treasury, supply cap and the MAZE token address are fixed when the contract is deployed.
contract MazeDino is ERC721 {
    using SafeERC20 for IERC20;
    using Strings for uint256;

    IERC20 public immutable maze;
    address public immutable treasury;
    uint256 public immutable price;      // in MAZE base units (18 decimals)
    uint256 public immutable maxSupply;

    uint256 public totalSupply;
    mapping(uint256 => uint32) public dnaOf;

    event Hatched(address indexed owner, uint256 indexed tokenId, uint32 dna);

    constructor(IERC20 maze_, address treasury_, uint256 price_, uint256 maxSupply_) ERC721("MAZE DINO", "DINO") {
        require(address(maze_) != address(0) && treasury_ != address(0), "zero address");
        require(price_ > 0 && maxSupply_ > 0, "bad config");
        maze = maze_;
        treasury = treasury_;
        price = price_;
        maxSupply = maxSupply_;
    }

    /// @notice Pay `price` MAZE (approve this contract first) and hatch one dino with a random DNA.
    function hatch() external returns (uint256 id) {
        require(totalSupply < maxSupply, "all dinos hatched");
        id = ++totalSupply;
        uint32 dna = uint32(uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender, id))) % 100_000_000);
        dnaOf[id] = dna;
        maze.safeTransferFrom(msg.sender, treasury, price);
        _safeMint(msg.sender, id);
        emit Hatched(msg.sender, id, dna);
    }

    /// @notice Draw any DNA (handy for previews before hatching).
    function previewSvg(uint32 dna) external pure returns (string memory) {
        require(dna < 100_000_000, "dna must be 8 digits");
        return DinoRenderer.svg(dna);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        _requireOwned(id);
        uint32 dna = dnaOf[id];
        string memory image = string.concat("data:image/svg+xml;base64,", Base64.encode(bytes(DinoRenderer.svg(dna))));
        string memory json = string.concat(
            '{"name":"MAZE DINO #', id.toString(),
            '","description":"A collectible dino hatched with MAZE. Its look comes from its DNA number and is drawn fully on-chain.",',
            '"image":"', image, '","attributes":[', _attributes(dna), ']}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function _attributes(uint32 dna) private pure returns (string memory) {
        string[8] memory colors = ["Hot Pink", "Violet", "Mint", "Sunny", "Sky", "Coral", "Lime", "Ice"];
        string[4] memory eyes = ["Dot", "Shiny", "Sleepy", "Blush"];
        string[4] memory backs = ["No spikes", "Small spikes", "Big spikes", "Bumpy back"];
        string[4] memory patterns = ["Plain", "Spots", "Stripes", "Belly dots"];
        string[5] memory accs = ["None", "Party hat", "Bow", "Glasses", "Crown"];
        return string.concat(
            _attr("DNA", _pad8(dna)), ",",
            _attr("Color", colors[DinoRenderer.colorOf(dna)]), ",",
            _attr("Eyes", eyes[DinoRenderer.eyesOf(dna)]), ",",
            _attr("Back", backs[DinoRenderer.spikesOf(dna)]), ",",
            _attr("Pattern", patterns[DinoRenderer.patternOf(dna)]), ",",
            _attr("Accessory", accs[DinoRenderer.accOf(dna)])
        );
    }

    function _attr(string memory k, string memory v) private pure returns (string memory) {
        return string.concat('{"trait_type":"', k, '","value":"', v, '"}');
    }

    function _pad8(uint32 n) private pure returns (string memory) {
        bytes memory out = new bytes(8);
        for (uint256 i = 8; i > 0; i--) { out[i - 1] = bytes1(uint8(48 + n % 10)); n /= 10; }
        return string(out);
    }
}
