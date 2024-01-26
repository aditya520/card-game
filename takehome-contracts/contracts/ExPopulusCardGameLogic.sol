pragma solidity ^0.8.12;

import "./ExPopulusCards.sol";

contract ExPopulusCardGameLogic is ExPopulusCards("random") {
    mapping(address => uint8) public winningStreak;
    mapping(address => uint256[]) public userBattles;

    // mapping(uint256 => [])
    constructor() {}

    function battle(uint256[] memory _playerCardIds) external returns (uint256 battleId) {
        require(
            _playerCardIds.length <= 3 && _playerCardIds.length > 0,
            "ExPopulusCardGameLogic: You should send minimum 1 and maximum 3 cards."
        );

        // Checking if owner owns those cards
        for (uint256 i = 0; i < _playerCardIds.length; i++) {
            require(
                balanceOf(msg.sender, _playerCardIds[i]) == 1,
                "ExPopulusCardGameLogic: You don't own the cards that you provided."
            );
        }

        // Let's pick three random cards from the deck.
        uint256[] memory enemyDeck = generateEnemyDeck(_playerCardIds.length);

        // Game Status
        // 1 -> In Progress
        // 2 -> Draw
        // 3 -> PlayerWon
        // 4 -> EnemyWon
        uint8 status = 1;

        uint256 playerIndex = 0;
        uint256 enemyIndex = 0;

        uint256 nPlayerCards = _playerCardIds.length;
        uint256 nEnemyCards = enemyDeck.length;


        // Game Loop
        // Basic Attack
        // Death Handling
        while (status == 1) {

            if (nPlayerCards == 0 && nEnemyCards == 0) {
                status = 2;
                break;
            }
            if (nEnemyCards == 0) {
                status = 3;
                break;
            }
            if (nPlayerCards == 0) {
                status = 4;
                break;
            }
            
            NftData memory playerCard = cards[_playerCardIds[playerIndex % _playerCardIds.length]];
            if (playerCard.health < 1) {
                playerIndex++;
                nPlayerCards--;
                continue;
            }
            NftData memory enemyCard = cards[enemyDeck[enemyIndex % enemyDeck.length]];
             if (enemyCard.health < 1) {
                enemyIndex++;
                nEnemyCards--;
                continue;
            }

            // Abilities (This will happen only on first Iteration)
            

            // Fetch The abilities and Priorities
            require(
                abilityPriority[playerCard.ability] >= 0 &&
                    abilityPriority[playerCard.ability] < 3,
                "ExPopulusCardGameLogic: Priority not set for the cards"
            );
            require(
                abilityPriority[enemyCard.ability] >= 0 &&
                    abilityPriority[enemyCard.ability] < 3,
                "ExPopulusCardGameLogic: Priority not set for the cards"
            );

            uint8 playerCardAbilityPriority = abilityPriority[
                playerCard.ability
            ];
            uint8 enemyCardAbilityPriority = abilityPriority[enemyCard.ability];

            NftData memory firstCard = playerCard;
            NftData memory secondCard = enemyCard;
            if (playerCardAbilityPriority < enemyCardAbilityPriority) {
                firstCard = enemyCard;
                secondCard = playerCard;
            }
        }

        return 0;
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
    function attack(
        NftData memory _attacker,
        NftData memory _receiver
    ) internal pure returns (uint8 receiversHealth) {
        return _receiver.health - _attacker.health;
    }

    // Assumption: Random cards can be user cards as well.
    function generateEnemyDeck(
        uint256 _size
    ) internal view returns (uint256[] memory) {
        uint256[] memory enemyDeck = new uint256[](_size);
        for (uint256 i = 0; i < _size; i++) {
            enemyDeck[i] = uint256(block.prevrandao) % idCoutner; // Not using ChainLink VRF function to save time for now
        }

        return enemyDeck;
    }
}
