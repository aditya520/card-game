pragma solidity ^0.8.12;

import "./ExPopulusCards.sol";

contract ExPopulusCardGameLogic is ExPopulusCards("random") {
    mapping(address => uint8) public winningStreak;
    mapping(address => uint256[]) public userBattles;

    struct NftCardStatus {
        uint8 attack;
        int8 health;
        Ability ability;
        bool abilityUsed;
        bool alive;
    }

    // mapping(uint256 => [])
    constructor() {}

    function battle(
        uint256[] memory _playerCardIds
    ) external returns (uint256 battleId) {
        require(
            _playerCardIds.length <= 3 && _playerCardIds.length > 0,
            "ExPopulusCardGameLogic: You should send minimum 1 and maximum 3 cards."
        );

        NftCardStatus[] memory playerCards = new NftCardStatus[](
            _playerCardIds.length
        );

        // Checking if owner owns those cards and append the cards to the new array
        for (uint256 i = 0; i < _playerCardIds.length; i++) {
            require(
                balanceOf(msg.sender, _playerCardIds[i]) == 1,
                "ExPopulusCardGameLogic: You don't own the cards that you provided."
            );
            NftData memory c = cards[_playerCardIds[i]];
            playerCards[i] = NftCardStatus(
                c.attack,
                c.health,
                c.ability,
                false,
                true
            );
        }

        // Let's pick three random cards from the deck.
        uint256[] memory enemyCardsIds = generateEnemyDeck(
            _playerCardIds.length
        );

        NftCardStatus[] memory enemyCards = new NftCardStatus[](
            enemyCardsIds.length
        );

        for (uint256 i = 0; i < enemyCardsIds.length; i++) {
            NftData memory e = cards[enemyCardsIds[i]];
            enemyCards[i] = NftCardStatus(
                e.attack,
                e.health,
                e.ability,
                false,
                true
            );
        }

        // Game Status
        // 1 -> In Progress
        // 2 -> Draw
        // 3 -> PlayerWon
        // 4 -> EnemyWon
        uint8 status = 1;

        uint256 playerIndex = 0;
        uint256 enemyIndex = 0;

        uint256 nPlayerCards = _playerCardIds.length;
        uint256 nEnemyCards = enemyCardsIds.length;

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

            NftCardStatus memory currentPlayerCard = playerCards[playerIndex];
            NftCardStatus memory currentEnemyCard = playerCards[enemyIndex];

            // Abilities (This will happen only on first Iteration)

            bool playerAbility = false;
            bool enemyAbility = false;

            // Checking Player Ability
            if (currentPlayerCard.abilityUsed == false) {
                require(
                    abilityPriority[currentPlayerCard.ability] >= 0 &&
                        abilityPriority[currentPlayerCard.ability] < 3,
                    "ExPopulusCardGameLogic: Priority not set for the cards"
                );
                // Add further logic here
                playerAbility = true;
            }

            // Checking enemy ability
            if (currentEnemyCard.abilityUsed == false) {
                require(
                    abilityPriority[currentEnemyCard.ability] >= 0 &&
                        abilityPriority[currentEnemyCard.ability] < 3,
                    "ExPopulusCardGameLogic: Priority not set for the cards"
                );
        
                // Add futher logic here
                enemyAbility = true;
            }

            // To Check if we have to use abilities or not.
            if (playerAbility || enemyAbility) {

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
    ) internal pure returns (int8 receiversHealth) {
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
