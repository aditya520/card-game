pragma solidity ^0.8.12;

import "./ExPopulusCards.sol";

contract ExPopulusCardGameLogic is ExPopulusCards("random") {
    mapping(address => uint8) public winningStreak;
    mapping(address => uint256[]) public userBattles;
    uint256 battleId;

    struct NftCardStatus {
        uint8 attack;
        int8 health;
        Ability ability;
        bool abilityUsed;
        bool alive;
    }

    enum Action {
        None,
        Ability,
        Attack
    }

    // mapping(uint256 => [])
    constructor() {}

    // We can use Enumerable Sets to see duplicates in the ID cards. (TODO:)
    function battle(uint256[] memory _playerCardIds) external returns (uint256) {
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
            playerCards[i] = NftCardStatus(c.attack, c.health, c.ability, false, true);
        }

        // Let's pick three random cards from the deck.
        uint256[] memory enemyCardsIds = generateEnemyDeck(_playerCardIds.length);

        NftCardStatus[] memory enemyCards = new NftCardStatus[](
            enemyCardsIds.length
        );

        for (uint256 i = 0; i < enemyCardsIds.length; i++) {
            NftData memory e = cards[enemyCardsIds[i]];
            enemyCards[i] = NftCardStatus(e.attack, e.health, e.ability, false, true);
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
            if (!currentPlayerCard.alive) {
                playerIndex++;
                continue;
            }
            if (!currentEnemyCard.alive) {
                enemyIndex++;
                continue;
            }

            // Abilities (This will happen only on first Iteration)
            int8 playerAbilityPriority = -1;
            int8 enemyAbilityPriority = -1;

            // Checking Player Ability
            if (currentPlayerCard.abilityUsed == false) {
                require(
                    abilityPriority[currentPlayerCard.ability] >= 0 && abilityPriority[currentPlayerCard.ability] < 3,
                    "ExPopulusCardGameLogic: Priority not set for the cards"
                );
                // Add further logic here
                playerAbilityPriority = int8(abilityPriority[currentPlayerCard.ability]);
            }

            // Checking enemy ability
            if (currentEnemyCard.abilityUsed == false) {
                require(
                    abilityPriority[currentEnemyCard.ability] >= 0 && abilityPriority[currentEnemyCard.ability] < 3,
                    "ExPopulusCardGameLogic: Priority not set for the cards"
                );

                // Add futher logic here
                enemyAbilityPriority = int8(abilityPriority[currentEnemyCard.ability]);
            }

            if (playerAbilityPriority > -1 || enemyAbilityPriority > -1) {
                if (playerAbilityPriority > -1) {
                    // Player Has some Ability. Let's see all the conditions
                    currentPlayerCard.abilityUsed = true;

                    // If enemy doesn't have ability
                    if (enemyAbilityPriority < 0) {
                        // TODO: Add player's ability to the array for history (It could be any 3)
                        if (currentPlayerCard.ability == Ability.Roulette) {
                            // Player will play roulette
                            if (roulette()) {
                                status = 3;
                                break;
                            }
                            // Enemy will attack the player
                            currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);
                        }

                        // Player will attack enemy (This will happen irrespective of player's ability)
                        currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                    } else {
                        // Enemy have some Ability.
                        // Now we have the check the priority as well.
                        currentEnemyCard.abilityUsed = true;

                        if (currentPlayerCard.ability == Ability.Shield) {
                            if (currentEnemyCard.ability == Ability.Shield) {
                                // TODO: Record it
                                // Do Nothing and Continue
                            } else if (currentEnemyCard.ability == Ability.Roulette) {
                                if (roulette()) {
                                    // Enemy will play roulette
                                    status = 4;
                                    break;
                                }
                                // Player will attack the enemy
                                currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                            } else if (currentEnemyCard.ability == Ability.Freeze) {
                                // Now we check the priorities.
                                if (playerAbilityPriority > enemyAbilityPriority) {
                                    // Shield > Freeze

                                    // Player will attack the enemy
                                    currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                                } else {
                                    // Freeze > Shield
                                    // Enemy will attack the player
                                    currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);
                                }
                            }
                            // Player Shield Completed (TODO: Don't continue here. We have to check the health at the end.)
                            continue;
                        } else if (currentPlayerCard.ability == Ability.Freeze) {
                            if (currentEnemyCard.ability == Ability.Shield) {
                                if (playerAbilityPriority > enemyAbilityPriority) {
                                    // Freeze > Shield
                                    // Player will attack the enemy
                                    currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                                } else {
                                    // Shield > Freeze
                                    // Enemy will attack the player
                                    currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);
                                }
                            } else if (currentEnemyCard.ability == Ability.Freeze) {
                                // Player will attack the enemy
                                currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                            } else if (currentEnemyCard.ability == Ability.Roulette) {
                                if (enemyAbilityPriority > playerAbilityPriority) {
                                    if (roulette()) {
                                        // Enemy will play roulette
                                        status = 4;
                                        break;
                                    }
                                }

                                // Player will attack the enemy
                                currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                            }
                            // Player Freeze completed(TODO: Remove the continue Please Adi)
                            continue;
                        } else if (currentPlayerCard.ability == Ability.Roulette) {
                            // TODO: This part can be optimized
                            if (currentEnemyCard.ability == Ability.Shield) {
                                if (roulette()) {
                                    // Player will play roulette
                                    status = 3;
                                    break;
                                }

                                // Enemy will attack the player
                                currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);
                            } else if (currentEnemyCard.ability == Ability.Freeze) {
                                if (playerAbilityPriority > enemyAbilityPriority) {
                                    // Roulette > Freeze
                                    if (roulette()) {
                                        // Player will play roulette
                                        status = 3;
                                        break;
                                    }
                                }
                                // Enemy will attack the player
                                currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);
                            } else if (currentEnemyCard.ability == Ability.Roulette) {
                                if (roulette()) {
                                    // player will play roulette
                                    status = 3;
                                    break;
                                }
                                if (roulette()) {
                                    // Enemy will play roulette
                                    status = 4;
                                    break;
                                }

                                // Player will attack the enemy
                                currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);

                                // Enemy will attack the player
                                currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);
                            }

                            // Player Roulette is completed(TODO: Remove the continue again.)
                            continue;
                        }
                    }
                } else {
                    // Player Doesn't have any ability.

                    // It means Enemy will have the ability since it is going on under the condition.
                    currentEnemyCard.abilityUsed = true;

                    // TODO: Record it under the history array
                    if (currentEnemyCard.ability == Ability.Roulette) {
                        if (roulette()) {
                            // Enemy will play roulette
                            status = 4;
                            break;
                        }

                        // Player will attack the enemy
                        currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                     }

                    // Enemy will attack the player
                    currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);
                }
            } else {
                // No Abilities found. Just attack each other please.

                // Player will attack the enemy
                currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);

                // Enemy will attack the player
                currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);

            }


            // Now all abilities and attacks have happened. Let's see if the card survives or not.
            if (currentPlayerCard.health <= 0) {
                currentPlayerCard.alive = false;
                nPlayerCards--;
            }
            if (currentEnemyCard.health <= 0) {
                currentEnemyCard.alive = false;
                nEnemyCards--;
            }
        }

        if (status != 3) {
            winningStreak[msg.sender]++;
        } else {
            winningStreak[msg.sender] = 0;
        }

        battleId++;
        userBattles[msg.sender].push(battleId);

        return battleId;
    }


    // Helper Functions

    // better to record the attack here I believe,(But I have to pass that everytime. Let's think afterwards)
    function attack(uint8 _attackersAttack, int8 _receiverHealth) internal pure returns (int8 receiversHealth) {
        return _receiverHealth - int8(_attackersAttack);
    }

    // Assumption: Random cards can be user cards as well.
    function generateEnemyDeck(uint256 _size) internal view returns (uint256[] memory) {
        uint256[] memory enemyDeck = new uint256[](_size);
        for (uint256 i = 0; i < _size; i++) {
            enemyDeck[i] = uint256(block.prevrandao) % idCoutner; // Not using ChainLink VRF function to save time for now
        }

        return enemyDeck;
    }

    function roulette() internal view returns (bool) {
        if (uint256(block.prevrandao) % 10 == 0) {
            return true;
        }

        return false;
    }
}
