// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ExPopulusToken is ERC20{

	address gameContract;

	constructor() ERC20("BattleRewards","BR"){
		gameContract = msg.sender;
	}

// TODO: Add access control
	function _mintToken(address _to, uint256 _amount) internal {
		require(msg.sender == gameContract, "ExPopulusToken: Sorry you can't mint the token.");
		_mint(_to, _amount);
	}
}
