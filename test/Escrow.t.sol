// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Escrow.sol";

contract EscrowTest is Test {
    Escrow public escrow;

    address buyer = address(1);
    address seller = address(2);
    address arbiter = address(3);

    function setUp() public {
        escrow = new Escrow();
        vm.deal(buyer, 10 ether);
    }

    function testCreateAndFundEscrow() public {
        vm.prank(buyer);
        uint256 id = escrow.createEscrow(seller, arbiter, 1 ether, block.timestamp + 1 days, "Test Escrow");

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(id);

        Escrow.EscrowDetails memory details = escrow.getEscrowDetails(id);
        assertEq(uint(details.status), uint(Escrow.EscrowStatus.Funded));
        assertFalse(details.isDisputed);
    }

    function testReleaseFunds() public {
        vm.prank(buyer);
        uint256 id = escrow.createEscrow(seller, arbiter, 1 ether, block.timestamp + 1 days, "Test");

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(id);

        vm.prank(seller);
        escrow.releaseFunds(id);

        Escrow.EscrowDetails memory details = escrow.getEscrowDetails(id);
        assertEq(uint(details.status), uint(Escrow.EscrowStatus.Released));
    }

    function testRequestRefundAfterDeadline() public {
    address buyer = vm.addr(1);
    address seller = vm.addr(2);
    address arbiter = vm.addr(3);

    uint256 startTime = 1000;
    vm.warp(startTime);

    vm.deal(buyer, 2 ether);

    vm.prank(buyer);
    uint256 id = escrow.createEscrow(seller, arbiter, 1 ether, startTime + 86400, "Refund test");

    vm.prank(buyer);
    escrow.fundEscrow{value: 1 ether}(id);

    vm.warp(startTime + 86401);

    console.log("Current Time:", block.timestamp);
    console.log("Deadline:", escrow.getEscrowDetails(id).deadline);
    console.log("Time Difference:", block.timestamp - escrow.getEscrowDetails(id).deadline);

    vm.prank(buyer);
    escrow.requestRefund(id);

    Escrow.EscrowDetails memory details = escrow.getEscrowDetails(id);
    assertEq(uint(details.status), uint(Escrow.EscrowStatus.Refunded));
}

    function testDisputeResolutionToSeller() public {
        vm.prank(buyer);
        uint256 id = escrow.createEscrow(seller, arbiter, 1 ether, block.timestamp + 1 days, "Dispute test");

        vm.prank(buyer);
        escrow.fundEscrow{value: 1 ether}(id);

        vm.prank(arbiter);
        escrow.resolveDispute(id, true);

        Escrow.EscrowDetails memory details = escrow.getEscrowDetails(id);
        assertEq(uint(details.status), uint(Escrow.EscrowStatus.Resolved));
        assertTrue(details.isDisputed);
    }
}
