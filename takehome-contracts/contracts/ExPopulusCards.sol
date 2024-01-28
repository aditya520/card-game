pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Random.sol";

contract ExPopulusCards is ERC1155, Ownable {
    uint256 public idCoutner;
    

    // We can use a map for abilities as it gives us an option to include more abilities in later game.
    enum Ability {
        Shield, Freeze, Roulette
    }

    struct NftData {
        uint8 attack;
        int8 health;
        Ability ability;
    }

    mapping(uint256 => NftData) public cards;
    mapping(address => bool) public approvedAddressesForMinting;
    mapping(Ability => uint8) public abilityPriority;
    // mapping(uint8 => Ability) public priorityAbility; // Can't have Enum as the zero value will be attack.



    constructor(string memory _uri) ERC1155 (_uri) Ownable(msg.sender){ // We can hardcode the URI, but it is always better to pass it via the constructor
    	idCoutner = 1;
        abilityPriority[Ability.Shield] = 2;
        abilityPriority[Ability.Freeze] = 1;
        abilityPriority[Ability.Roulette] = 0;
    }

    modifier onlyOwnerOrApproved() {
        require(owner() == msg.sender || approvedAddressesForMinting[msg.sender], "ExPopulusCards: You don't have access to mint cards.");
        _;
    }

    function mintCard(address _to, uint8 _attack, int8 _health, Ability _ability) external onlyOwnerOrApproved {
        require(uint8(_ability) < 3, "ExPopulusCards: Only Ability 0, 1 and 2 allowed.");
        _mint(_to, idCoutner, 1, "");
        cards[idCoutner] = NftData(_attack,_health, _ability);
        idCoutner++;

    }

    function getCardDetails(uint256 _cardId) public view returns(uint8 attack, int8 health, Ability ability){
        NftData storage card = cards[_cardId];
        return (card.attack, card.health, card.ability);
    }



    // In this I will udpate the new priority and and put the existing one to other ability having that.
    // Current 
    // Shield = 2, Freeze = 1, Roulette = 0
    // Incoming Freeze = 2
    // Updated: Shield = 1, Freeze = 2, Roulette = 0
    function setPriority(Ability _ability, uint8 _priority) external onlyOwner {
        require(_priority < 3, "ExPopulusCards: Only Priority 0, 1 and 2 allowed.");
        require(abilityPriority[_ability] != _priority, "ExPopulusCards: The given ability aready have the priority.");
        uint8 existingPriority = abilityPriority[_ability];

        abilityPriority[checkPriority(_priority)] = existingPriority;
        abilityPriority[_ability] = _priority;
    }



	// Utility Functions

	function approveAddressForMinting(address _to) external onlyOwner {
		approvedAddressesForMinting[_to] = true;
	}

    function checkPriority(uint8 _priority) internal view returns(Ability) {
        for (uint8 i = 0; i < 3; i++) {
            if (abilityPriority[Ability(i)] == _priority) {
                return Ability(i);
            }
        }
    }

}

