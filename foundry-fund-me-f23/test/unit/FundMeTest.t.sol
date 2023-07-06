// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    FundMe fundMe;
    address USER = makeAddr("user");

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 constant SEND_VALUE = 11e18;
    uint256 constant MIN_USD = 5e18;
    uint256 constant VERSION = 4;
    uint256 constant BALANCE = 20 ether;
    uint256 constant GAS_PRICE = 10;

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() external {
        // us -> FundMeTest -> FundMe
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, BALANCE);
    }

    /// -----------------------------------------------------------------------
    /// User action tests
    /// -----------------------------------------------------------------------

    function testMinimumDollarsIsFive() public {
        // ensure that in the FundMe contract, MINMUM_USD state variable is $5
        assertEq(fundMe.MINIMUM_USD(), MIN_USD);
    }

    function testOwner() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testFeedVersionIs4() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, VERSION);
    }

    function testFundFailsWithoutEnoughUsd() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructures() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testFundUpdatesArray() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.startPrank(USER);
        vm.expectRevert();
        fundMe.cheaperWithdraw();
        vm.stopPrank();
    }

    function testWithdrawFundsViaOwner() public funded {
        // Arrange
        uint256 ownerStartingBalance = fundMe.getOwner().balance;
        uint256 fundMeStatingBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // Assert
        uint256 ownerEndingBlance = fundMe.getOwner().balance;
        uint256 fundMeEndingBalance = address(fundMe).balance;

        assertEq(fundMeEndingBalance, 0);
        assertEq(ownerStartingBalance + fundMeStatingBalance, ownerEndingBlance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;

        for (uint160 i = startingIndex; i < numberOfFunders + startingIndex; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.startPrank(address(fundMe.getOwner()));
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingContractBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingIndex = 1;

        for (uint160 i = startingIndex; i < numberOfFunders + startingIndex; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.startPrank(address(fundMe.getOwner()));
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingContractBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}
