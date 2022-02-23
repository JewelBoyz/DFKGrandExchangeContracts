// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import {IERC20} from "./interfaces/IERC20.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";
import {SellOffer} from "./SellOffer.sol";

contract BuyOffer {
    address public constant USDC = 0x985458E523dB3d53125813eD68c274899e9DfAb4;
    address public constant UST = 0x224e64ec1BDce3870a6a6c777eDd450454068FEC;
    address public constant JEWEL = 0x72Cb10C6bfA5624dD07Ef608027E366bd690048F;

    address public factory;
    address public buyer;
    address public paymentToken;
    uint256 public fee;
    address public item;
    uint256 public itemCount;
    bool public closed = false;
    
    event OfferComplete(address seller,address item,uint256 itemCount,address paymentToken,uint256 paymentAmount);
    event OfferPartialComplete(address seller,address item,uint256 itemCount,address paymentToken,uint256 paymentAmount);

    event OfferCanceled(address item,uint256 itemCount,address paymentToken,uint256 paymentAmount);

    constructor(
        address _buyer,
        address _paymentToken,
        uint256 _paymentAmount,
        address _item,
        uint256 _itemCount,
        uint256 _fee
    ) public {
        factory = msg.sender;
        buyer = _buyer;
        paymentToken = _paymentToken;
        item = _item;
        itemCount = _itemCount;
        fee = _fee;
        //fund contract with payment moneys
        require(IERC20(_paymentToken).balanceOf(_buyer)>= _paymentAmount,"Amount willing to pay exceeds amount available");
        safeTransferFrom(_paymentToken,_buyer, address(this),_paymentAmount);
    }
    

    //thx for the code uniswap ;)
    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function withdraw(address token) public{
        require(msg.sender == IOwnable(factory).owner());
        if(token == 0x0000000000000000000000000000000000000000){
            payable(IOwnable(factory).owner()).transfer(address(this).balance);
        }else{
            uint256 balance = IERC20(token).balanceOf(address(this));
            safeTransfer(token, IOwnable(factory).owner(),balance);
        }
    }
    function completeOrder(SellOffer sellOffer) public{
        require(!closed,"Order already completed");
        require(!sellOffer.closed(), "Sell order already complete");
        require(sellOffer.factory() == factory,"Factory discrepency");
        //price per item from seller, used later to determine if refund is needed
        //multiplied by 10,000 for easy calculations, solidity doesn't like smol numbers
        uint256 sellerPricePerItem = (sellOffer.paymentAmount() * 10_000)/IERC20(item).balanceOf(address(sellOffer));
        uint256 itemCountForTransaction = (itemCount >= IERC20(item).balanceOf(address(sellOffer))) ? IERC20(item).balanceOf(address(sellOffer)) : itemCount;
        uint256 paymentAmountForTransaction = (IERC20(paymentToken).balanceOf(address(this)) >= sellOffer.paymentAmount()) ? sellOffer.paymentAmount() : IERC20(paymentToken).balanceOf(address(this));
        //pull service fee from buyer amount
        uint256 serviceFee = (paymentAmountForTransaction*fee)/10_000;
        //final amount seller is getting
        uint256 finalAmount = paymentAmountForTransaction-serviceFee;
        
        //transfer serviceFee to factory owner
        safeTransfer(paymentToken, IOwnable(factory).owner(), serviceFee);
        //transfer item to this contract
        safeTransferFrom(item,address(sellOffer), address(this), itemCountForTransaction);
        //transfer rest of payment amount to seller
        safeTransferFrom(paymentToken,address(this),sellOffer.seller(),finalAmount);
        //transfer item to buyer
        safeTransfer(item,buyer,itemCount);
        //refund?? if price per item is less than balance remaining
        uint256 remaining = IERC20(paymentToken).balanceOf(address(this));
        if (sellerPricePerItem > (remaining*10_000))
        {
            //price you paid for one item is more than the remaining balance, refund rest
            safeTransfer(paymentToken,buyer,remaining);
        }
        //else no refund stay open

        // update sell and buy itemCount/paymentAmount 
        itemCount -= itemCountForTransaction;
        sellOffer.adjustPaymentAmount(paymentAmountForTransaction);
        
        if (IERC20(paymentToken).balanceOf(address(this)) == 0){
            closed = true;
            emit OfferComplete(sellOffer.seller(),item,itemCountForTransaction,paymentToken,paymentAmountForTransaction);
        }else{
            emit OfferPartialComplete(sellOffer.seller(),item,itemCountForTransaction,paymentToken,paymentAmountForTransaction);
        }
        if (IERC20(item).balanceOf(address(sellOffer)) == 0){
            sellOffer.close(buyer,item,itemCountForTransaction,paymentToken,paymentAmountForTransaction);
        }else{
            sellOffer.partialComplete(buyer,item,itemCountForTransaction,paymentToken,paymentAmountForTransaction);
        }
    }
    function cancelOrder() public{
        require(hasToken(),"No token on this address");
        require(msg.sender == buyer,"This address is not the buyer");
        uint256 balance = IERC20(paymentToken).balanceOf(address(this));
        safeTransfer(paymentToken,buyer,balance);
        closed = true;
        emit OfferCanceled(item,itemCount,paymentToken,balance);
    }
    function hasToken() public view returns (bool){
        return IERC20(paymentToken).balanceOf(address(this)) > 0;
    }
}