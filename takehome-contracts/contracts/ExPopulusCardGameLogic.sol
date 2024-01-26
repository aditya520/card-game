pragma solidity ^0.8.12;

import "./ExPopulusCards.sol";

contract ExPopulusCardGameLogic is ExPopulusCards{

	mapping(address => uint8) public winningStreak;
	mapping(address => uint256[]) public userBattles;
	// mapping(uint256 => [])
	constructor() {

	}

	function battle(uint256[] memory _playerCardIds) external returns (uint256 battleId) {
		require(_playerCardIds.length <= 3 && _playerCardIds.length > 0, "ExPopulusCardGameLogic: You should send minimum 1 and maximum 3 cards.");

		// Checking if owner owns those cards
		for(uint256 i = 0; i < _playerCardIds.length; i++){
			require(balanceOf(msg.sender, _playerCardIds[i]) == 1,"ExPopulusCardGameLogic: You don't own the cards that you provided.");
		}

		// Let's pick three random cards from the deck.
		uint256[] memory enemyDeck = generateEnemyDeck(_playerCardIds.length)


		// Game Loop


	}


	/*

	// To see if they have played ability do (index <  length(cards)); it mean they have not used the ability

	userShieldPlayer: bool
	userShieldEnemy: bool

	usedFreezedPlayer: bool
	userdFreezedEnemy: bool

	Shield > Freeze > Rou
	player 				enemy
1.  Sh					Sh			DO Nothing
2. 	Sh					Freeze		Player will attack enemy
3. Freeze				Sh				Enemy will attack Player
4. Freeze				Freeze		Player will attack enemy

	Freeze > Sheid > R

1. Sh					Sh  			Do Nothing
2. Sh					Freeze			Enemy will attack Player
3. Freeze				Sh				Player will attack enemy
4. Freeze				Freeze			Player will attack enemy


for Roulette = getRandomNumber % 10 == 1; Return


	while game.status == Inprogress {
		playerFrontIndex , EnemyFrontIndex := 0 / length(cards),0
		// Clone the cards everytime,

		1. Figure out the priority.
		2. Check if the health !=0
		3. If it same, then give user the first preference
		4. 
		5. 
	}

	function attack(card1, card2) returns (card1, card2)

	*/

	// Helper Functions


	// Assumption: Random cards can be user cards as well.
	function generateEnemyDeck(uint256 _size) internal returns (uint256[] memory) {
        uint256[] memory enemyDeck = new uint256[](_size);
        for (uint256 i = 0; i < _size; i++) {
            enemyDeck[i] = getRandomCardId();
        }

        return enemyDeck;
    }


	// Not using ChainLink VRF function to save time for now
    function getRandomCardId() internal view returns (uint256) {
        return uint256(block.prevrandao) % idCoutner;
    }

}
