// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {Test, console} from "forge-std/Test.sol";
import {RealEstatePlatform} from "src/RealEstatePlatform.sol";

contract RealEstatePlatformTest is Test {
    RealEstatePlatform realEstatePlatform;
    address platformOwner = makeAddr("PLATFORMOWNER");
    address seller = makeAddr("Seller");
    address buyer = makeAddr("Buyer");
    uint256 public constant MIN_LISTING_FEE = 1e18;
    uint256 constant PROPERTY_COST = 10e18;

    function setUp() public {
        vm.prank(platformOwner);
        realEstatePlatform = new RealEstatePlatform();
    }

    /***********************************************************************************************/
    /**                             PUBLIC FUNCTIONS                                               */
    /***********************************************************************************************/

    function testListProperty() public {
        (
            bytes32 expectedHash,
            bytes32 actualHash
        ) = _addPropertyAndReturnHash();

        assertEq(expectedHash, actualHash);
        //Verify that counter got increased or not
        assertEq(realEstatePlatform.counter(), 1);
        // Verify that the platform received the expected listing fee
        assertEq(address(realEstatePlatform).balance, MIN_LISTING_FEE);
    }

    function testPurchaseProperty() public {
        _addPropertyAndReturnHash();
        vm.prank(buyer);
        vm.deal(buyer, PROPERTY_COST);
        realEstatePlatform.purchaseProperty{value: PROPERTY_COST}(0);

        // Before the purchase, the seller's balance should be zero since they haven't received any funds yet.
        // Once the buyer purchases the property, the seller's balance should increase by the property cost.
        // This is why i compare the seller's balance with PROPERTY_COST after the purchase.
        assertEq(seller.balance, PROPERTY_COST);
    }

    function testWithdrawAndGetPlatformBalanceFromPlatform() public {
        _addPropertyAndReturnHash();
        vm.prank(platformOwner);
        uint256 platformBalance = realEstatePlatform.getPlatformBalance();
        vm.prank(platformOwner);
        realEstatePlatform.withdrawBalanceFromPlatform();
        assertEq(platformOwner.balance, MIN_LISTING_FEE);
        assertEq(platformBalance, MIN_LISTING_FEE);
    }

    function testGetPropertyList() public {
        (
            bytes32 expectedHash,
            bytes32 actualHash
        ) = _addPropertyAndReturnHash();

        uint256 propertyListLength = realEstatePlatform
            .getPropertyList()
            .length;

        assertEq(expectedHash, actualHash);
        assertEq(propertyListLength, 1);
    }

    function testIsPlatformOwner() public {
        vm.prank(buyer);
        bool checkWithNonPltfOwner = realEstatePlatform.isPlatformOwner();

        vm.prank(platformOwner);
        bool checkWithPltfOwner = realEstatePlatform.isPlatformOwner();

        assertEq(checkWithNonPltfOwner, false);
        assertEq(checkWithPltfOwner, true);
    }

    function testGetPropertyByID() public {
        (
            bytes32 expectedHash , 
        ) = _addPropertyAndReturnHash();

        // Buyer tries to fetch property by ID
        vm.prank(buyer);
        RealEstatePlatform.PropertyDetails memory property = realEstatePlatform
            .getPropertyById(0);

        // Recompute hash from returned struct to compare with expected
        bytes32 propertyHash = keccak256(
            abi.encode(
                property.propertyName,
                property.location,
                property.costOfProperty,
                property.propertyDescription,
                property.propertyImages,
                property.propertyOwnerAddress,
                property.id
            )
        );

        assertEq(
            propertyHash,
            expectedHash,
            "Property details do not match expected values"
        );
    }

    /***********************************************************************************************/
    /**                             INTERNAL FUNCTIONS                                             */
    /***********************************************************************************************/

    function _addPropertyAndReturnHash() internal returns (bytes32, bytes32) {
        string memory _propertyName = "Dream Home";
        string memory _location = "123 Main Street, Metropolis";
        uint256 _costOfProperty = PROPERTY_COST;
        string
            memory _propertyDescription = "A beautiful 4-bedroom house with a garden.";
        string memory _propertyImages = "image1.jpg,image2.jpg";

        vm.prank(seller);
        vm.deal(seller, MIN_LISTING_FEE);

        realEstatePlatform.listProperty{value: MIN_LISTING_FEE}(
            _propertyName,
            _location,
            _costOfProperty,
            _propertyDescription,
            _propertyImages
        );
        (
            string memory propertyName,
            string memory location,
            uint256 costOfProperty,
            string memory propertyDescription,
            string memory propertyImages,
            ,
            address propertyOwnerAddress,
            uint256 id
        ) = realEstatePlatform.s_propertyDetails(0);

        bytes32 expectedHash = keccak256(
            abi.encode(
                _propertyName,
                _location,
                _costOfProperty,
                _propertyDescription,
                _propertyImages,
                seller,
                0
            )
        );

        bytes32 actualHash = keccak256(
            abi.encode(
                propertyName,
                location,
                costOfProperty,
                propertyDescription,
                propertyImages,
                propertyOwnerAddress,
                id
            )
        );

        return (expectedHash, actualHash);
    }
}
