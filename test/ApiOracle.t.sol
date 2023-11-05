// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/OracleApi.sol";

contract OracleApiTest is Test {
    OracleApi oracleApi;
    uint256 fees = 2 ether;
    address owner = address(0x0123);

    address userA = address(0x0a);

    address userNotRegistrated = address(0x0b);

    address userWithNoBalance = address(0x0c);

    uint256 apiKey = 1;
    string urlToFetchRandomNumbers = "https://www.randomnumberapi.com/api/v1.0/random?min=100&max=1000";
    string response = "123";

    function setUp() public {
        oracleApi = new OracleApi();
        oracleApi.setFees(fees);
        oracleApi.addNewUser(apiKey, userA);
        assertEq(oracleApi.flatFee(), fees, "Incorrect fees value available");
        assertEq(oracleApi.apiKeyByAddress(userA), apiKey, "API key is incorrect");
    }

    function testOracleFullRequest() public {
        vm.startPrank(userA);
        vm.deal(userA, fees);
        uint256 id = oracleApi.requestOracle{value: fees}(urlToFetchRandomNumbers);
        assertTrue(oracleApi.pendingRequests(id));
        vm.stopPrank();

        oracleApi.setOracleResult(0, urlToFetchRandomNumbers, response);
        assertFalse(oracleApi.pendingRequests(0));
    }

    function testRevertIfUserHasNotRegistred() public {
        vm.startPrank(userNotRegistrated);
        vm.deal(userNotRegistrated, fees);
        vm.expectRevert();
        oracleApi.requestOracle{value: fees}(urlToFetchRandomNumbers);
    }

    function testRevertIfUserHasNoFees() public {
        oracleApi.addNewUser(apiKey, userWithNoBalance);
        oracleApi.addNewUser(apiKey, userWithNoBalance);
        vm.startPrank(userWithNoBalance);
        vm.expectRevert();
        oracleApi.requestOracle{value: fees}(urlToFetchRandomNumbers);
    }

    function testOwnerWithdrawAllFees() public {
        vm.deal(address(oracleApi), fees);
        uint256 balanceBefore = address(oracleApi).balance;
        assertEq(balanceBefore, fees, "Oracle didn't collect fees");
        oracleApi.transferOwnership(owner);
        vm.prank(owner);

        oracleApi.withdrawAll();
        uint256 balanceAfter = address(oracleApi).balance;
        assertEq(balanceAfter, 0, "Owner didn't withdrawAll");
    }
}
