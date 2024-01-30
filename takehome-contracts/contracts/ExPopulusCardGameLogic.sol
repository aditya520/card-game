// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./ExPopulusCards.sol";
import "./ExPopulusToken.sol";
import "hardhat/console.sol";

contract ExPopulusCardGameLogic is ExPopulusToken{
    mapping(address => uint8) public winningStreak;
    mapping(address => uint256[]) public userBattles;
    uint256 battleId;

    struct NftCardStatus {
        uint8 attack;
        int8 health;
        ExPopulusCards.Ability ability;
        bool abilityUsed;
        bool alive;
    }

    // enum Action {
    //     None,
    //     Ability,
    //     Attack
    // }

    ExPopulusCards exPopulusCards;

    // mapping(uint256 => [])
    constructor(address _exPopulusCards) ExPopulusToken()
    {
        exPopulusCards = ExPopulusCards(_exPopulusCards);
    }

    // TODO: add battleEnemy Function (uint256[] memory _playerCardIds, uint256[] memory _enemyCardIds)
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
                exPopulusCards.balanceOf(msg.sender, _playerCardIds[i]) > 0,
                "ExPopulusCardGameLogic: You don't own the cards that you provided."
            );
            (uint8 playerAttack, int8 health, ExPopulusCards.Ability ability) = exPopulusCards.cards(_playerCardIds[i]);
            playerCards[i] = NftCardStatus(playerAttack, health, ability, false, true);
        }

        // Let's pick three random cards from the deck.
        uint256[] memory enemyCardsIds = generateEnemyDeck(_playerCardIds.length);
        for(uint8 i = 0; i < enemyCardsIds.length; i++) {
            console.log("Enemy Id is:" ,enemyCardsIds[i]);
        }

        NftCardStatus[] memory enemyCards = new NftCardStatus[](
            enemyCardsIds.length
        );

        for (uint256 i = 0; i < enemyCardsIds.length; i++) {
            (uint8 enemyAttack, int8 health, ExPopulusCards.Ability ability) = exPopulusCards.cards(enemyCardsIds[i]);
            enemyCards[i] = NftCardStatus(enemyAttack, health, ability, false, true);
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

            NftCardStatus memory currentPlayerCard = playerCards[playerIndex % _playerCardIds.length];
            NftCardStatus memory currentEnemyCard = enemyCards[enemyIndex % enemyCardsIds.length];
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
                    exPopulusCards.abilityPriority(currentPlayerCard.ability) >= 0 && exPopulusCards.abilityPriority(currentPlayerCard.ability) < 3,
                    "ExPopulusCardGameLogic: Priority not set for the cards"
                );
                // Add further logic here
                playerAbilityPriority = int8(exPopulusCards.abilityPriority(currentPlayerCard.ability));
            }

            // Checking enemy ability
            if (currentEnemyCard.abilityUsed == false) {
                require(
                    exPopulusCards.abilityPriority(currentEnemyCard.ability) >= 0 && exPopulusCards.abilityPriority(currentEnemyCard.ability) < 3,
                    "ExPopulusCardGameLogic: Priority not set for the cards"
                );

                // Add futher logic here
                enemyAbilityPriority = int8(exPopulusCards.abilityPriority(currentEnemyCard.ability));
            }
            console.log("playerIndex",playerIndex,"enemyIndex",enemyIndex);
            if (playerAbilityPriority > -1 || enemyAbilityPriority > -1) {
                
                if (playerAbilityPriority > -1) {
                    // Player Has some Ability. Let's see all the conditions
                    currentPlayerCard.abilityUsed = true;

                    // If enemy doesn't have ability
                    if (enemyAbilityPriority < 0) {
                        // TODO: Add player's ability to the array for history (It could be any 3)
                        if (currentPlayerCard.ability == ExPopulusCards.Ability.Roulette) {
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

                        if (currentPlayerCard.ability == ExPopulusCards.Ability.Shield) {
                            if (currentEnemyCard.ability == ExPopulusCards.Ability.Shield) {
                                // TODO: Record it
                                // Do Nothing and Continue
                            } else if (currentEnemyCard.ability == ExPopulusCards.Ability.Roulette) {
                                if (roulette()) {
                                    // Enemy will play roulette
                                    status = 4;
                                    break;
                                }
                                // Player will attack the enemy
                                currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                            } else if (currentEnemyCard.ability == ExPopulusCards.Ability.Freeze) {
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
                        } else if (currentPlayerCard.ability == ExPopulusCards.Ability.Freeze) {
                            if (currentEnemyCard.ability == ExPopulusCards.Ability.Shield) {
                                if (playerAbilityPriority > enemyAbilityPriority) {
                                    // Freeze > Shield
                                    // Player will attack the enemy
                                    currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                                } else {
                                    // Shield > Freeze
                                    // Enemy will attack the player
                                    currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);
                                }
                            } else if (currentEnemyCard.ability == ExPopulusCards.Ability.Freeze) {
                                // Player will attack the enemy
                                currentEnemyCard.health = attack(currentPlayerCard.attack, currentEnemyCard.health);
                            } else if (currentEnemyCard.ability == ExPopulusCards.Ability.Roulette) {
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
                        } else if (currentPlayerCard.ability == ExPopulusCards.Ability.Roulette) {
                            // TODO: This part can be optimized
                            if (currentEnemyCard.ability == ExPopulusCards.Ability.Shield) {
                                if (roulette()) {
                                    // Player will play roulette
                                    status = 3;
                                    break;
                                }

                                // Enemy will attack the player
                                currentPlayerCard.health = attack(currentEnemyCard.attack, currentPlayerCard.health);
                            } else if (currentEnemyCard.ability == ExPopulusCards.Ability.Freeze) {
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
                            } else if (currentEnemyCard.ability == ExPopulusCards.Ability.Roulette) {
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
                        }
                    }
                } else {
                    // Player Doesn't have any ability.

                    // It means Enemy will have the ability since it is going on under the condition.
                    currentEnemyCard.abilityUsed = true;

                    // TODO: Record it under the history array
                    if (currentEnemyCard.ability == ExPopulusCards.Ability.Roulette) {
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

            playerIndex++;
            enemyIndex++;
        }

        if (status == 3) {
            winningStreak[msg.sender]++;
            if (winningStreak[msg.sender] % 5 == 0) {
                // Mint 1000 tokens
            } else {
                // Mint 100 tokens
            }
        } else {
            winningStreak[msg.sender] = 0;
        }

        battleId++;
        userBattles[msg.sender].push(battleId);
        console.log("Status: ",status);

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
            enemyDeck[i] = uint256(block.prevrandao) % exPopulusCards.idCounter(); // Not using ChainLink VRF function to save time for now
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
