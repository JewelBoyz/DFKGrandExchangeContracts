// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {IERC20} from "./interfaces/IERC20.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";
// import {UniswapV2Pair} from "@uniswapv2/UniswapV2Pair.sol";

contract PublicOffer {
    address public constant USDC = 0x985458E523dB3d53125813eD68c274899e9DfAb4;
    address public constant UST = 0x224e64ec1BDce3870a6a6c777eDd450454068FEC;
    address public constant JEWEL = 0x72Cb10C6bfA5624dD07Ef608027E366bd690048F;

    address public immutable factory;
    address public immutable seller;
    address public immutable paymentToken;
    uint256 public immutable paymentAmount;
    uint256 public immutable fee;
    address public immutable item;
    bool public closed = false;
    
    event OfferComplete(address buyer,address item,uint256 itemCount,address paymentToken,uint256 paymentAmount);
    event OfferCanceled(address buyer,address item,uint256 itemCount);

    constructor(
        address _seller,
        address _paymentToken,
        uint256 _paymentAmount,
        address _item,
        uint256 _fee
    ){
        factory = msg.sender;
        seller = _seller;
        paymentToken = _paymentToken;
        paymentAmount = _paymentAmount;
        item = _item;
        fee = _fee;
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
    function completeOrder() public{
        require(hasToken(),"No item on this address");
        require(!closed,"Order already completed");

        uint256 balance = IERC20(item).balanceOf(address(this));

        uint256 serviceFee = (paymentAmount*fee)/10_000;

        uint256 finalAmount = paymentAmount-serviceFee;        
        
        safeTransferFrom(paymentToken, msg.sender, IOwnable(factory).owner(), serviceFee);
        safeTransferFrom(paymentToken,msg.sender,seller,finalAmount);
        safeTransfer(item,msg.sender,balance);
        closed = true;
        emit OfferComplete(msg.sender,item,balance,paymentToken,paymentAmount);
    }
    function cancelOrder() public{
        require(hasToken(),"No item on this address");
        require(msg.sender == seller,"This address is not the seller");
        uint256 balance = IERC20(item).balanceOf(address(this));
        safeTransfer(item,seller,balance);
        closed = true;
        emit OfferCanceled(seller,item,balance);
    }
    function hasToken() public view returns (bool){
        return IERC20(item).balanceOf(address(this)) > 0;
    }
}