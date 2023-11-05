// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/OraclePrice.sol";

contract OraclePriceTest is Test {
    OraclePrice oraclePrice;
    uint256 fees = 2 ether;
    address owner = address(0x0123);

    address userA = address(0x0a);

    address userNotRegistrated = address(0x0b);

    address userWithNoBalance = address(0x0c);

    uint256 apiKey = 1;
    string fiatSymbol = "USD";
    string cryptoSymbol = "ETH";

    function setUp() public {
        oraclePrice = new OraclePrice();
        oraclePrice.setFees(fees);
        oraclePrice.addNewUser(apiKey, userA);
        assertEq(oraclePrice.flatFee(), fees, "Incorrect fees value available");
        assertEq(oraclePrice.apiKeyByAddress(userA), apiKey, "API key is incorrect");
    }

    function testOracleFullRequest() public {
        vm.startPrank(userA);
        vm.deal(userA, fees);
        uint256 id = oraclePrice.requestOracle{value: fees}(fiatSymbol, cryptoSymbol);
        assertTrue(oraclePrice.pendingRequests(id));
        vm.stopPrank();

        oraclePrice.setOracleResult(0, fiatSymbol, 2);
        assertFalse(oraclePrice.pendingRequests(0));
    }

    function testRevertIfUserHasNotRegistred() public {
        vm.startPrank(userNotRegistrated);
        vm.deal(userNotRegistrated, fees);
        vm.expectRevert();
        oraclePrice.requestOracle{value: fees}(fiatSymbol, cryptoSymbol);
    }

    function testRevertIfUserHasNoFees() public {
        oraclePrice.addNewUser(apiKey, userWithNoBalance);
        oraclePrice.addNewUser(apiKey, userWithNoBalance);
        vm.startPrank(userWithNoBalance);
        vm.expectRevert();
        oraclePrice.requestOracle{value: fees}(fiatSymbol, cryptoSymbol);
    }

    function testOwnerWithdrawAllFees() public {
        vm.deal(address(oraclePrice), fees);
        uint256 balanceBefore = address(oraclePrice).balance;
        assertEq(balanceBefore, fees, "Oracle didn't collect fees");
        oraclePrice.transferOwnership(owner);
        vm.prank(owner);

        oraclePrice.withdrawAll();
        uint256 balanceAfter = address(oraclePrice).balance;
        assertEq(balanceAfter, 0, "Owner didn't withdrawAll");
    }
}
