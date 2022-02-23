// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import {Ownable} from "./open-zeppelin/Ownable.sol";
import {SellOffer} from "./SellOffer.sol";
import {BuyOffer} from "./BuyOffer.sol";


contract OfferFactory is Ownable {
    uint256 public fee = 150; //1.5%
    BuyOffer[] public buyOffers;
    SellOffer[] public sellOffers; 

    event OfferCreated(address offerAddress,address item,uint256 itemCount, address paymentToken,uint256 amount);

    function setFee(uint256 _fee) public onlyOwner { 
        fee = _fee;
    }
    function createBuyOrder(address item, uint256 itemCount, address paymentToken, uint256 paymentAmount) public returns (BuyOffer) {
        BuyOffer offer = new BuyOffer(msg.sender,paymentToken,paymentAmount,item,itemCount,fee);
        emit OfferCreated(address(offer),item, itemCount, paymentToken, paymentAmount);
        //try to look through sell offers and complete
        //if completed, no need to add to array
        for(uint256 i;i<sellOffers.length;i++){
            SellOffer sell = SellOffer(sellOffers[i]);
            if (sell.item() == item && sell.paymentToken() == paymentToken && !sell.closed()){
                offer.completeOrder(sell);
                if (offer.closed()){
                    return offer;
                }
            }
        }
        buyOffers.push(offer); 
        return offer;
    }
    function createSellOrder(address item, uint256 itemCount, address paymentToken, uint256 paymentAmount) public returns (SellOffer) {
        SellOffer offer = new SellOffer(msg.sender,paymentToken,paymentAmount,item,itemCount,fee);
        emit OfferCreated(address(offer),item, itemCount, paymentToken, paymentAmount);
        //try to look through sell offers and complete
        //if completed, no need to add to array
        for(uint256 i;i<buyOffers.length;i++){
            BuyOffer buy = BuyOffer(buyOffers[i]);
            if (buy.item() == item && buy.paymentToken() == paymentToken && !buy.closed()){
                buy.completeOrder(offer);
                if (offer.closed()){
                    return offer;
                }
            }
        }
        sellOffers.push(offer); 
        return offer;
    }
    // function getPublicActiveOffers() public view returns (PublicOffer[] memory){
    //     PublicOffer[] memory activeOffers = new PublicOffer[](publicOffers.length);
    //     uint256 count;
    //     for (uint256 i; i < publicOffers.length; i++){
    //         PublicOffer offer = PublicOffer(publicOffers[i]);
    //         if (offer.hasToken() && !offer.closed()){
    //             activeOffers[count++] = offer;
    //         }
    //     }
    //     return activeOffers;
    // }
}