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

    // We can use Enumerable Sets to see duplicates in the ID cards. (TODO:)
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

            int8 playerAbilityPriority = -1;
            int8 enemyAbilityPriority = -1;

            // Checking Player Ability
            if (currentPlayerCard.abilityUsed == false) {
                require(
                    abilityPriority[currentPlayerCard.ability] >= 0 &&
                        abilityPriority[currentPlayerCard.ability] < 3,
                    "ExPopulusCardGameLogic: Priority not set for the cards"
                );
                // Add further logic here
                playerAbility = true;
                playerAbilityPriority = int8(abilityPriority[currentPlayerCard.ability]);
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
                enemyAbilityPriority = int8(abilityPriority[currentEnemyCard.ability]);
            }

            // To Check if we have to use abilities or not.
            if (playerAbilityPriority > -1 || enemyAbilityPriority > -1) {
                if (playerAbilityPriority >= enemyAbilityPriority) {            // Player Ability will be played first.
                    if (currentPlayerCard.ability == 0) {                   // Player have Shield

                    }
                }       
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
1.  Sh					Sh			Null
2. 	Sh					Freeze		P -> E
3. Sh                   Roulette    P -> E   &  R(E)
4. Sh                   Nothing     P -> E


5. Freeze				Sh			E -> P
6. Freeze				Freeze		P -> E
7. Freeze               Roulette    P -> E
8. Freeze               Nothing     P -> E

9. Roulette             Shield      E -> P   &  R(P)
10. Roulette            Freeze      E -> P
11. Roulette            Roulette    R(P)     &  R(E)
12. Roulette            Noting      R(P)     &  E <-> P

13. Nothing             Sh          E -> P
14. Nothing             Freeze      E -> P
15. Nothing             Roulette    R(E)     &  E <-> P
16. Nothing             Nothing     E <-> P

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
