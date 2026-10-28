// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MazeDino} from "../src/MazeDino.sol";

contract MockMaze is ERC20 {
    constructor() ERC20("MAZE", "MAZE") { _mint(msg.sender, 1_000_000_000_000_000 ether); }
}

contract MazeDinoTest is Test {
    MockMaze maze;
    MazeDino dino;
    address treasury = address(0xBEEF);
    address alice = address(0xA11CE);
    uint256 constant PRICE = 10_000 ether;

    function setUp() public {
        maze = new MockMaze();
        dino = new MazeDino(maze, treasury, PRICE, 1000);
        maze.transfer(alice, 100_000_000 ether);
        vm.prank(alice);
        maze.approve(address(dino), type(uint256).max);
    }

    function test_hatch_pays_treasury_and_mints() public {
        vm.prank(alice);
        uint256 id = dino.hatch();
        assertEq(id, 1);
        assertEq(dino.ownerOf(1), alice);
        assertEq(dino.totalSupply(), 1);
        assertEq(maze.balanceOf(treasury), PRICE);
        assertEq(maze.balanceOf(alice), 100_000_000 ether - PRICE);
        assertLt(dino.dnaOf(1), 100_000_000);
    }

    function test_hatch_reverts_without_allowance() public {
        address bob = address(0xB0B);
        maze.transfer(bob, PRICE);
        vm.prank(bob);
        vm.expectRevert();
        dino.hatch();
        assertEq(dino.totalSupply(), 0);
    }

    function test_hatch_reverts_without_balance() public {
        address bob = address(0xB0B);
        vm.startPrank(bob);
        maze.approve(address(dino), type(uint256).max);
        vm.expectRevert();
        dino.hatch();
        vm.stopPrank();
    }

    function test_supply_cap() public {
        MazeDino small = new MazeDino(maze, treasury, PRICE, 3);
        vm.startPrank(alice);
        maze.approve(address(small), type(uint256).max);
        small.hatch(); small.hatch(); small.hatch();
        vm.expectRevert(bytes("all dinos hatched"));
        small.hatch();
        vm.stopPrank();
        assertEq(small.totalSupply(), 3);
        assertEq(maze.balanceOf(treasury), 3 * PRICE);
    }

    function test_transfer_and_tokenURI() public {
        vm.prank(alice);
        dino.hatch();
        vm.prank(alice);
        dino.transferFrom(alice, address(0xCAFE), 1);
        assertEq(dino.ownerOf(1), address(0xCAFE));
        string memory uri = dino.tokenURI(1);
        assertEq(_startsWith(uri, "data:application/json;base64,"), true);
        vm.expectRevert();
        dino.tokenURI(2);
    }

    function test_constructor_rejects_bad_config() public {
        vm.expectRevert(bytes("zero address"));
        new MazeDino(maze, address(0), PRICE, 10);
        vm.expectRevert(bytes("bad config"));
        new MazeDino(maze, treasury, 0, 10);
    }

    /// The on-chain SVG must equal the Python reference for every sample DNA.
    function test_svg_matches_reference() public view {
        uint32[26] memory samples = [uint32(0), 1211300, 2033101, 3312405, 4122207, 5231019, 6302142, 7120433,
            99999999, 12345678, 87654321, 31415926, 27182818, 10203040, 40302010, 55555555, 11111111,
            22222222, 33333333, 44444444, 66666666, 77777777, 88888888, 19283746, 70011996, 3000000];
        for (uint256 i = 0; i < samples.length; i++) {
            string memory expected = vm.readFile(string.concat("test/ref/", _pad8(samples[i]), ".svg"));
            assertEq(dino.previewSvg(samples[i]), expected, _pad8(samples[i]));
        }
    }

    function test_every_trait_value_renders() public view {
        // walk each digit position through 0-9 so every branch (and the modulo wrap) runs
        for (uint32 v = 0; v < 10; v++) {
            dino.previewSvg(v * 11_111_111);
            dino.previewSvg(v * 1_000_000);
            dino.previewSvg(v * 100_000);
            dino.previewSvg(v * 10_000);
            dino.previewSvg(v * 1_000);
            dino.previewSvg(v * 100);
        }
    }

    function test_preview_rejects_big_dna() public {
        vm.expectRevert(bytes("dna must be 8 digits"));
        dino.previewSvg(100_000_000);
    }

    function _pad8(uint32 n) internal pure returns (string memory) {
        bytes memory out = new bytes(8);
        for (uint256 i = 8; i > 0; i--) { out[i - 1] = bytes1(uint8(48 + n % 10)); n /= 10; }
        return string(out);
    }

    function _startsWith(string memory s, string memory p) internal pure returns (bool) {
        bytes memory a = bytes(s); bytes memory b = bytes(p);
        if (a.length < b.length) return false;
        for (uint256 i = 0; i < b.length; i++) if (a[i] != b[i]) return false;
        return true;
    }
}
