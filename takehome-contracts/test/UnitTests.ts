import hre from "hardhat";
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import {Signers} from "../types";
import chai, {expect} from "chai";
import chaiAsPromised from "chai-as-promised";
import {deployContracts} from "../deploy_scripts/main";
import assert from "assert";

describe("Unit tests", function () {

	before(async function () {
		chai.should();
		chai.use(chaiAsPromised);

		// Set up a signer for easy use
		this.signers = {} as Signers;
		const signers: SignerWithAddress[] = await hre.ethers.getSigners();
		this.signers.creator = signers[0];
		this.signers.testAccount1 = signers[1];
		this.signers.testAccount2 = signers[2];

		// Deploy the contracts
		this.contracts = await deployContracts();

		this.health10 = 10;
		this.attack10 = 10;
		this.health20 = 20;
		this.attack20 = 20;
		this.abilityShield = 0;
		this.abilityRoulette = 1;
		this.abilityFreeze = 2;
		this.card1 = 1;
		this.card2 = 2;
	});

	describe("User Story #1 (Minting)", async function () {
		it("Can mint a card to a specific player & verify ownership afterwards", async function () {
			// Minting a new NFT to testAccount1
			await this.contracts.exPopulusCards.connect(this.signers.creator)
			.mintCard(this.signers.testAccount1.address,this.health10,this.attack10,this.abilityShield);

			// Minting a new NFT to testAccount2
			await this.contracts.exPopulusCards.connect(this.signers.creator)
			.mintCard(this.signers.testAccount2.address,this.health20,this.attack20,this.abilityRoulette);

			// Verifying ownership
			var nBalanceOfAccount1 = await this.contracts.exPopulusCards.connect(this.signers.testAccount1)
			.balanceOf(this.signers.testAccount1.address,this.card1);
			
			assert(nBalanceOfAccount1.gt(0));

			var nBalanceOfAccount2 = await this.contracts.exPopulusCards.connect(this.signers.testAccount2)
			.balanceOf(this.signers.testAccount2.address,this.card2);

			assert(nBalanceOfAccount2.gt(0));
		});

		it("Contract Owner can allow an address to mint cards", async function () {
		
			await this.contracts.exPopulusCards.connect(this.signers.creator).approveAddressForMinting(this.signers.testAccount1.address);

			await this.contracts.exPopulusCards.connect(this.signers.testAccount1)
			.mintCard(this.signers.testAccount2.address,this.health20,this.attack20,this.abilityRoulette);
		
			var nBalanceOfAccount2 = await this.contracts.exPopulusCards.connect(this.signers.testAccount2)
			.balanceOf(this.signers.testAccount2.address,this.card2);

			assert(nBalanceOfAccount2.gt(0));

			await expect(this.contracts.exPopulusCards.connect(this.signers.testAccount2)
			.mintCard(this.signers.testAccount2.address,this.health20,this.attack20,this.abilityRoulette)).to.be.reverted;
			
		});

	});

	describe("User Story #2 (Ability Configuration)", async function () {
		it("Setting Priority and swapping them", async function() {
			var priority2 = await this.contracts.exPopulusCards.abilityPriority(0);
			assert(priority2 == 2);

			var priority1 = await this.contracts.exPopulusCards.abilityPriority(2);
			assert(priority1 == 1);

			await this.contracts.exPopulusCards.connect(this.signers.creator).setPriority(0,0);

			var priority2 = await this.contracts.exPopulusCards.abilityPriority(0);
			assert(priority2 == 0);

			var priority0 = await this.contracts.exPopulusCards.abilityPriority(1);
			assert(priority0 == 2);
		})
	});

	describe("User Story #3 (Battles & Game Loop)", async function () {
			it.only("Battle Testing", async function () {
			// Let's mint 4 nfts.

			

			await this.contracts.exPopulusCards.connect(this.signers.creator)
				.mintCard(this.signers.testAccount1.address, this.health10, this.attack10, this.abilityShield);

				console.log(await this.contracts.exPopulusCards.cards(1));
				console.log(await this.contracts.exPopulusCards.connect(this.signers.testAccount1)
					.balanceOf(this.signers.testAccount1.address,1))


			await this.contracts.exPopulusCards.connect(this.signers.creator)
				.mintCard(this.signers.testAccount1.address, this.health20, this.attack20, this.abilityRoulette);

				console.log(await this.contracts.exPopulusCards.cards(2));
				console.log(await this.contracts.exPopulusCards.connect(this.signers.testAccount1)
					.balanceOf(this.signers.testAccount1.address,2))

			await this.contracts.exPopulusCards.connect(this.signers.creator)
				.mintCard(this.signers.testAccount1.address, this.health10, this.attack10, this.abilityFreeze);

				console.log(await this.contracts.exPopulusCards.cards(3));
				console.log(await this.contracts.exPopulusCards.connect(this.signers.testAccount1)
					.balanceOf(this.signers.testAccount1.address,3))

			await this.contracts.exPopulusCards.connect(this.signers.creator)
				.mintCard(this.signers.testAccount1.address, this.health10, this.attack10, this.abilityShield);

				console.log(await this.contracts.exPopulusCards.cards(4));
				console.log(await this.contracts.exPopulusCards.connect(this.signers.testAccount1)
					.balanceOf(this.signers.testAccount1.address,4))

			console.log(this.signers.testAccount1.address);

			// Call Battle Function

			await this.contracts.exPopulusCardGameLogic.connect(this.signers.testAccount1)
				.battle([1, 2, 3]);
		})
	});

	describe("User Story #4 (Fungible Token & Battle Rewards)", async function () {
	});

	describe("User Story #5 (Battle Logs & Historical Lookup)", async function () {
	});
});
