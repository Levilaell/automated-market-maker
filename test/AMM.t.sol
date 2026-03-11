// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {AMM} from "../src/AMM.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract AMMTest is Test {
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    AMM public amm;
    address public alice;

    function setUp() public {
        tokenA = new MockERC20("Ethereum", "ETH");
        tokenB = new MockERC20("Dolar", "USD");
        amm = new AMM(address(tokenA), address(tokenB));
        alice = makeAddr("alice");

        vm.startPrank(alice);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();

        tokenA.mint(alice, 1000 ether);
        tokenB.mint(alice, 1000 ether);
    }

    function test_AddLiquidity() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        assertEq(amm.reserveA(), 100 ether);
        assertEq(amm.reserveB(), 100 ether);
        assertGt(amm.balanceOf(alice), 0);
    }

    function test_RemoveLiquidity() public {
        vm.startPrank(alice);
        amm.addLiquidity(100 ether, 100 ether);
        amm.removeLiquidity(amm.balanceOf(alice));
        vm.stopPrank();

        assertEq(amm.reserveA(), 0);
        assertEq(amm.reserveB(), 0);
        assertGt(tokenA.balanceOf(alice), 900);
    }

    function test_Swap() public {
        vm.startPrank(alice);
        amm.addLiquidity(500 ether, 500 ether);
        amm.swap(address(tokenA), 10 ether);
        vm.stopPrank();

        assertGt(tokenB.balanceOf(alice), 500 ether);
        assertGt(amm.reserveA(), 500 ether);
    }

    function test_RevertWhen_InvalidToken() public {
        vm.prank(alice);
        amm.addLiquidity(100 ether, 100 ether);

        vm.expectRevert("invalid token");
        vm.prank(alice);
        amm.swap(address(0), 10 ether);
    }

    function test_RevertWhen_InsufficientLiquidity() public {
        vm.expectRevert("insufficient liquidity");
        vm.prank(alice);
        amm.addLiquidity(0, 0);
    }

    function test_RevertWhen_RemoveZeroLiquidity() public {
        vm.expectRevert("insufficient liquidity");
        vm.prank(alice);
        amm.removeLiquidity(0);
    }
}
