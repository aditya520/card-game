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
			var cardId1 = 1;
			var nBalanceOfAccount1 = await this.contracts.exPopulusCards.connect(this.signers.testAccount1)
			.balanceOf(this.signers.testAccount1.address,cardId1);
			
			assert(nBalanceOfAccount1.gt(0));
			
			var cardId2 = 2;
			var nBalanceOfAccount2 = await this.contracts.exPopulusCards.connect(this.signers.testAccount2)
			.balanceOf(this.signers.testAccount2.address,cardId2);

			assert(nBalanceOfAccount2.gt(0));


			// Getting card Details
			await this.contracts.exPopulusCards.connect(this.signers.creator)
			.getCardDetails(cardId1);

			// await this.contracts.exPopulusCards.connect(this.signers.testAccount1)
			// .getCardDetails(cardId1);

			// var card = await this.contracts.exPopulusCards.connect(this.signers.testAccount2)
			// .getCardDetails(cardId1);
			// console.log(card);

			
		});
	});

	describe("User Story #2 (Ability Configuration)", async function () {
	});

	describe("User Story #3 (Battles & Game Loop)", async function () {
	});

	describe("User Story #4 (Fungible Token & Battle Rewards)", async function () {
	});

	describe("User Story #5 (Battle Logs & Historical Lookup)", async function () {
	});
});
