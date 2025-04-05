const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GovernmentPropertyVerification", function () {
  let contract;
  let owner;
  let addr1;
  let addr2;
  let agent;

  beforeEach(async function () {
    [owner, addr1, addr2, agent] = await ethers.getSigners();
    const GovernmentPropertyVerification = await ethers.getContractFactory("GovernmentPropertyVerification");
    contract = await GovernmentPropertyVerification.deploy();
  });

  describe("Basic Functions", function () {
    it("Should set the right owner", async function () {
      expect(await contract.owner()).to.equal(owner.address);
    });

    it("Should create a property token", async function () {
      const price = ethers.parseEther("1");
      await contract.createPropertyToken("uri/test", price, addr1.address, "Test Property");
      const properties = await contract.fetchProperties();
      expect(properties.length).to.equal(1);
      expect(properties[0].price).to.equal(price);
    });

    it("Should allow agent to approve property transfer", async function () {
      const price = ethers.parseEther("1");
      await contract.setAgent(agent.address, true);
      await contract.createPropertyToken("uri/test", price, addr1.address, "Test Property");
      await contract.connect(agent).approvePropertyTransfer(1);
      const properties = await contract.fetchProperties();
      expect(properties[0].approved).to.equal(true);
    });
  });
});
