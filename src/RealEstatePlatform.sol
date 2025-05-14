// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract RealEstatePlatform {
    /***********************************************************************************************/
    /***                                       ERRORS                                            ***/
    /***********************************************************************************************/
    error RealEstatePlatform__NotAPlatformOwner();
    error RealEstatePlatform__InSufficientAmountToBuyAProperty();
    error RealEstatePlatform__NoBalanceToWithdraw();
    error RealEstatePlatform__AsPropertyOwnerCannotPurchase();
    error RealEstatePlatform__ListingFeeLowerThanMinListingFee();
    error RealEstatePlatform__InValidAddressCannotListProperty();

    /***********************************************************************************************/
    /**                                       EVENTS                                              **/
    /***********************************************************************************************/
    event PropertyAdded(
        address indexed owner,
        uint256 indexed propertyId,
        string message
    );
    event PropertyPurchased(
        address indexed buyer,
        uint256 indexed propertyId,
        uint256 amountPaid,
        string message
    );
    event BalanceWithdrawnByPlatformOwner(
        address indexed platformOwner,
        uint256 amount,
        string message
    );

    /***********************************************************************************************/
    /***                                       STRUCTS                                           ***/
    /***********************************************************************************************/

    struct PropertyDetails {
        string propertyName; // Name of the property
        string location; // Full address of the property
        uint256 costOfProperty; // Price in ETH
        string propertyDescription; // Description from the owner's perspective
        string propertyImages; // Static IPFS URL for property images
        uint256 timeStamp; // block time stamp
        address propertyOwnerAddress; // propety owner  address
        uint256 id;
    }

    /***********************************************************************************************/
    /***                                       STORAGE                                            **/
    /***********************************************************************************************/
    uint256 public constant MIN_LISTING_FEE = 1e18;
    address private immutable i_platformOwner;
    mapping(uint256 count => PropertyDetails) public s_propertyDetails;
    uint256 public counter = 0;

    /***********************************************************************************************/
    /***                                       MODIFIERS                                          **/
    /***********************************************************************************************/

    modifier onlyPlatformOwner() {
        if (msg.sender != i_platformOwner) {
            revert RealEstatePlatform__NotAPlatformOwner();
        }
        _;
    }

    /**
     * Set contract deployer as platform owner
     */
    constructor() {
        i_platformOwner = msg.sender;
    }

    /***********************************************************************************************/
    /**                             PUBLIC FUNCTIONS                                               */
    /***********************************************************************************************/

    /**
     * @notice Adds a new property to the platform with the specified details.
     * This function allows property owners to list their properties on the platform.
     * A platform fee in ETH is charged for each property listing, which is transferred to the platform owner.
     */
    function listProperty(
        string memory _propertyName,
        string memory _location,
        uint256 _costOfProperty,
        string memory _propertyDescription,
        string memory _propertyImages
    ) public payable {
        if (msg.value < MIN_LISTING_FEE) {
            revert RealEstatePlatform__ListingFeeLowerThanMinListingFee();
        }

        if (msg.sender == address(0)) {
            revert RealEstatePlatform__InValidAddressCannotListProperty();
        }

        s_propertyDetails[counter] = PropertyDetails({
            propertyName: _propertyName,
            location: _location,
            costOfProperty: _costOfProperty,
            propertyDescription: _propertyDescription,
            propertyImages: _propertyImages,
            timeStamp: block.timestamp,
            propertyOwnerAddress: msg.sender,
            id: counter
        });
        emit PropertyAdded(msg.sender, counter, "Property Added Successfully");
        counter++;
    }

    /**
     * @notice Allows a user to buy a property listed on the platform.
     * Transfers the payment to the property owner and removes the property from the platform.
     * @param propertyID The ID of the property to be purchased.
     */
    function purchaseProperty(uint256 propertyID) public payable {
        if (msg.value < s_propertyDetails[propertyID].costOfProperty) {
            revert RealEstatePlatform__InSufficientAmountToBuyAProperty();
        }

        if (s_propertyDetails[propertyID].propertyOwnerAddress == msg.sender) {
            revert RealEstatePlatform__AsPropertyOwnerCannotPurchase();
        }

        uint256 cost = s_propertyDetails[propertyID].costOfProperty;
        address seller = s_propertyDetails[propertyID].propertyOwnerAddress;

        delete s_propertyDetails[propertyID];
        payable(seller).transfer(cost);

        emit PropertyPurchased(
            msg.sender,
            propertyID,
            msg.value,
            "Property purchased successfully"
        );
    }

    /**
     *  Transfers the entire balance of the contract to the platform owner's address.
     * @notice This function can only be called by the platform owner.
     * It ensures that all accumulated fees are securely transferred to the platform owner.
     */
    function withdrawBalanceFromPlatform() public onlyPlatformOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert RealEstatePlatform__NoBalanceToWithdraw();
        }
        payable(i_platformOwner).transfer(balance);
        emit BalanceWithdrawnByPlatformOwner(
            i_platformOwner,
            balance,
            "Platform balance withdrawn"
        );
    }

    // Checks if the caller is the platform owner.
    // Call `isPlatformOwner()` to verify if the current user has the platform owner role.
    function isPlatformOwner() public view returns (bool) {
        return msg.sender == i_platformOwner;
    }

    /***********************************************************************************************/
    /**                             GETTER FUNCTIONS                                               */
    /***********************************************************************************************/

    /**
     * The platform collects a small fee from both buyers and sellers for facilitating transactions.
     * This function allows the platform owner to view the total balance of fees accumulated by the contract.
     * @notice Only the platform owner is authorized to call this function and check the platform's balance.
     */
    function getPlatformBalance()
        public
        view
        onlyPlatformOwner
        returns (uint256)
    {
        return address(this).balance;
    }

    /**
     * @notice Retrieves the list of all properties added to the platform.
     * This function is restricted to the platform owner and returns an array of PropertyDetails.
     * @return An array containing details of all properties listed on the platform.
     */
    function getPropertyList() public view returns (PropertyDetails[] memory) {
        PropertyDetails[] memory propertyList = new PropertyDetails[](counter);
        for (uint256 i = 0; i < counter; i++) {
            if(s_propertyDetails[i].propertyOwnerAddress != address(0)){
                 propertyList[i] = s_propertyDetails[i];
            }
           
        }
        return propertyList;
    }

    function getPropertyById (uint256 id) public view returns( PropertyDetails memory){
        return  s_propertyDetails[id];
    }

    /***********************************************************************************************/
    /**                             INTERNAL FUNCTIONS                                             */
    /***********************************************************************************************/

    // No internal functions 😢
}
