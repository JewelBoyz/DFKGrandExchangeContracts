// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import {Ownable} from "./open-zeppelin/Ownable.sol";
import{PublicOffer} from "./PublicOffer.sol";

contract OfferFactory is Ownable {
    uint256 public fee = 150; //1.5%
    PublicOffer[] public publicOffers;

    event OfferCreated(address offerAddress,address item,address paymentToken,uint256 amount);

    function setFee(uint256 _fee) public onlyOwner { 
        fee = _fee;
    }
    function createPublicOffer(address item, address paymentToken,uint256 amount) public returns (PublicOffer){
        PublicOffer offer = new PublicOffer(msg.sender,paymentToken,amount,item,fee);
        publicOffers.push(offer);
        emit OfferCreated(address(offer),item,paymentToken,amount);
        return offer; 
    }
    function getPublicActiveOffers() public view returns (PublicOffer[] memory){
        PublicOffer[] memory activeOffers = new PublicOffer[](publicOffers.length);
        uint256 count;
        for (uint256 i; i < publicOffers.length; i++){
            PublicOffer offer = PublicOffer(publicOffers[i]);
            if (offer.hasToken() && !offer.closed()){
                activeOffers[count++] = offer;
            }
        }
        return activeOffers;
    }
    // function getCompleteOffers() public view returns (PublicOffer[] memory,PrivateOffer[] memory){
    //     PublicOffer[] memory closedPublicOffers = new PublicOffer[](publicOffers.length);
    //     uint256 countPublic;
    //     for (uint256 i; i < publicOffers.length; i++){
    //         PublicOffer offer = PublicOffer(publicOffers[i]);
    //         if (offer.closed()){
    //             closedPublicOffers[countPublic++] = offer;
    //         }
    //     }
    //     PrivateOffer[] memory closedPrivateOffers = new PrivateOffer[](privateOffers.length);
    //     uint256 countPrivate;
    //     for (uint256 i; i < privateOffers.length; i++){
    //         PrivateOffer offer = PrivateOffer(privateOffers[i]);
    //         if (offer.closed()){
    //             closedPrivateOffers[countPrivate++] = offer;
    //         }
    //     }
    //     return (closedPublicOffers,closedPrivateOffers);
    // }
}