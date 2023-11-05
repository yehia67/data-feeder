// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/BaseOracle.sol";

contract BaseOracleTest is Test {
    BaseOracle baseOracle;
    uint256 fees = 2 ether;
    address notOwner = address(0x0b);

    address userA = address(0x0a);
    uint256 apiKey = 1;

    function setUp() public {
        baseOracle = new BaseOracle();
    }

    function testSetFees() public {
        baseOracle.setFees(fees);
        assertEq(baseOracle.flatFee(), fees, "Incorrect fees value available");
    }

    function testSetFeesRevertIfNotOwner() public {
        vm.prank(notOwner);
        vm.expectRevert();
        baseOracle.setFees(fees);
    }

    function testAllowUserA() public {
        baseOracle.addNewUser(apiKey, userA);
        assertEq(baseOracle.apiKeyByAddress(userA), apiKey, "API key is incorrect");
    }

    function testAllowUserARevertIfNotOwner() public {
        vm.prank(notOwner);
        vm.expectRevert();
        baseOracle.addNewUser(apiKey, userA);
    }
}
