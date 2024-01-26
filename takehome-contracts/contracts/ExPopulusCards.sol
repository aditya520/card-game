pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Random.sol";

contract ExPopulusCards is ERC1155, Ownable {
    uint256 public idCoutner;
    

    // We can use a map for abilities as it gives us an option to include more abilities in later game.
    enum Ability {
        Shield, Roulette, Freeze
    }

    struct NftData {
        uint8 attack;
        int8 health;
        Ability ability;
    }

    mapping(uint256 => NftData) public cards;
    mapping(address => bool) public approvedAddressesForLookup;
    mapping(Ability => uint8) public abilityPriority;
    // mapping(uint8 => Ability) public priorityAbility; // Can't have Enum as the zero value will be attack.



    constructor(string memory _uri) ERC1155 (_uri) Ownable(msg.sender){ // We can hardcode the URI, but it is always better to pass it via the constructor
    	idCoutner = 1;
        abilityPriority[Ability.Shield] = 0;
        abilityPriority[Ability.Freeze] = 1;
        abilityPriority[Ability.Roulette] = 2;
    }

    modifier onlyOwnerOrApproved() {
        require(owner() == msg.sender || approvedAddressesForLookup[msg.sender], "ExPopulusCards: You don't have access of the card.");
        _;
    }

    function mintCard(address _to, uint8 _attack, int8 _health, Ability _ability) external onlyOwner {
        require(uint8(_ability) < 3, "ExPopulusCards: Only Ability 0, 1 and 2 allowed.");
        
        _mint(_to, idCoutner, 1, "");
        cards[idCoutner] = NftData(_attack,_health, _ability);
        // approveAddressForLookup(_to);
        idCoutner++;

    }

    function getCardDetails(uint256 _cardId) external view onlyOwnerOrApproved returns(uint8 attack, int8 health, Ability ability){
        NftData storage card = cards[_cardId];
        return (card.attack, card.health, card.ability);
    }



// You won't be able to change the priority as checkPriority will never work. Fix this.
    function setPriority(Ability _ability, uint8 _priority) external onlyOwner {
        require(_priority < 3, "ExPopulusCards: Only Priority 0, 1 and 2 allowed.");
        require(!checkPriority(_priority), "ExPopulusCards: Priority already assigned.");
        abilityPriority[_ability] = _priority;

        
    }



	// Utility Functions

    // It's more of an admin role. That user can see all cards. (****ASSUMPTION*****)
    // We can make one for each user seperately but they can fetch it seperately. (Let's circle back to this)
	function approveAddressForLookup(address _to) private onlyOwner {
		approvedAddressesForLookup[_to] = true;
	}

    function checkPriority(uint8 _priority) internal view returns(bool) {
        return (abilityPriority[Ability.Shield] == _priority || abilityPriority[Ability.Roulette] == _priority || abilityPriority[Ability.Freeze] == _priority);
    }
}

