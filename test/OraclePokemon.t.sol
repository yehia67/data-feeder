// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/OraclePokemon.sol";

contract OraclePokemonTest is Test {
    OraclePokemon oraclePokemon;
    uint256 fees = 2 ether;
    address owner = address(0x0123);

    address userA = address(0x0a);

    address userNotRegistrated = address(0x0b);

    address userWithNoBalance = address(0x0c);

    uint256 apiKey = 1;
    string tokenUri = "https://pokeapi.co/api/v2/pokemon/1017";

    function setUp() public {
        oraclePokemon = new OraclePokemon();
        oraclePokemon.setFees(fees);
        oraclePokemon.addNewUser(apiKey, userA);
        assertEq(oraclePokemon.flatFee(), fees, "Incorrect fees value available");
        assertEq(oraclePokemon.apiKeyByAddress(userA), apiKey, "API key is incorrect");
    }

    function testOracleFullRequest() public {
        vm.startPrank(userA);
        vm.deal(userA, fees);
        uint256 id = oraclePokemon.requestOracle{value: fees}();
        assertTrue(oraclePokemon.pendingRequests(id));
        vm.stopPrank();

        oraclePokemon.setOracleResult(0, userA, tokenUri);
        assertFalse(oraclePokemon.pendingRequests(0));
        assertEq(oraclePokemon.ownerOf(0), userA, "User didn't recive NFT");
    }

    function testRevertIfUserHasNotRegistred() public {
        vm.startPrank(userNotRegistrated);
        vm.deal(userNotRegistrated, fees);
        vm.expectRevert();
        oraclePokemon.requestOracle{value: fees}();
    }

    function testRevertIfUserHasNoFees() public {
        oraclePokemon.addNewUser(apiKey, userWithNoBalance);
        oraclePokemon.addNewUser(apiKey, userWithNoBalance);
        vm.startPrank(userWithNoBalance);
        vm.expectRevert();
        oraclePokemon.requestOracle{value: fees}();
    }

    function testOwnerWithdrawAllFees() public {
        vm.deal(address(oraclePokemon), fees);
        uint256 balanceBefore = address(oraclePokemon).balance;
        assertEq(balanceBefore, fees, "Oracle didn't collect fees");
        oraclePokemon.transferOwnership(owner);
        vm.prank(owner);

        oraclePokemon.withdrawAll();
        uint256 balanceAfter = address(oraclePokemon).balance;
        assertEq(balanceAfter, 0, "Owner didn't withdrawAll");
    }
}
