// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace {

    address payable public immutable feeAccount; 
    uint public immutable feePercent;  
    uint public itemCount; 
    address payable public immutable NGO;
    struct Item {
        uint itemId;
        IERC721 nft;
        uint tokenId;
        uint prevPrice;
        uint price;
        address payable seller;
        bool toBeSold;
        address payable creator;
        uint percentageDonated;
        uint royaltyPercentage;
    }

    mapping(uint => Item) public items;
    mapping(address => Item[]) public owned_nft;
    event Offered(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller
    );
    event Bought(
        uint itemId,
        address indexed nft,
        uint tokenId,
        uint price,
        address indexed seller,
        address indexed buyer
    );

    constructor(uint _feePercent) {
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
        NGO = payable(msg.sender);
    }

    function makeNFT(IERC721 _nft, uint _tokenId, uint _price, uint _percentageDonated, uint _royalty) external  {
        require(_price > 0, "Price must be greater than zero");
        itemCount ++;
        items[itemCount] = Item (
            itemCount,
            _nft,
            _tokenId,
            0,
            _price,
            payable(msg.sender),
            false,
            payable(msg.sender),
            _percentageDonated,
            _royalty
        );
        owned_nft[msg.sender].push(items[itemCount]);
    }

    function Buy(uint _itemId) external payable {
        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        uint _totalPrice = getTotalPrice(_itemId);
        require(msg.value <= _totalPrice, "not enough ether to cover item price and market fee");
        Item storage item = items[_itemId];
        require(!item.toBeSold, "item already sold");
        uint profit=getProfit(item.itemId);
        if(profit>0){
            uint ngo=item.percentageDonated/100*profit;
            uint royalty=0;
            if(item.creator!=item.seller){
                royalty=item.royaltyPercentage/100*profit;
            }
            NGO.transfer(ngo);
            item.creator.transfer(royalty);
            item.seller.transfer(item.price-ngo-royalty);
        }
        else{
            item.seller.transfer(item.price);
        }
        feeAccount.transfer(_totalPrice - item.price);
        item.toBeSold = false;
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);
        item.seller=payable(msg.sender);
        item.prevPrice=item.price;
        item.toBeSold=false;
        emit Bought(
            _itemId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            msg.sender
        );

    }

    function Sell(uint _itemId, uint _price) external payable{
        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        Item storage item = items[_itemId];
        require(item.seller==msg.sender);
        item.toBeSold= true;
        item.prevPrice=item.price;
        item.price=_price;
        emit Offered(
            itemCount,
            address(item.nft),
            _itemId,
            _price,
            msg.sender
        );
    }

    function removeNFT(uint _itemId) external{
        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        items[_itemId].toBeSold=false;
    }

    function getTotalPrice(uint _itemId) view public returns(uint){
        return((items[_itemId].price*(100 + feePercent))/100);
    }

    function updatePrice(uint _price, uint _itemId) external{
        require(_itemId > 0 && _itemId <= itemCount, "item doesn't exist");
        items[_itemId].price=_price;
    }

    function getNft() view external returns(Item[] memory){
        return owned_nft[msg.sender];
    }

    function getProfit(uint _itemId) view internal returns(uint){
        Item memory item=items[_itemId];
        return item.prevPrice-item.price;
    }
}