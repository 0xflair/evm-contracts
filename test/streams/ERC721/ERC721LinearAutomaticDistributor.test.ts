import { expect } from "chai";
import { utils, BigNumber } from "ethers";

import { ERC721LinearAutomaticDistributor } from "../../../typechain";

import { setupTest } from "../../setup";
import { increaseTime, ZERO_ADDRESS } from "../../utils/common";

describe("ERC721LinearAutomaticDistributor", function () {
  describe("Release Amount Calculation", function () {
    it("should calculate release amount correctly based on unit window", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA } = await setupTest();
      const contract =
        userA.ERC721LinearAutomaticDistributor as ERC721LinearAutomaticDistributor;

      await contract.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      const result = await contract.calculateReleasedAmountRounded(
        1,
        nowUnix + 5 * 24 * 60 * 60 // +5 days
      );

      expect(result.toString()).to.equal(utils.parseEther("5"));
    });

    it("should round down release amount correctly based on unit window", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA } = await setupTest();
      const contract =
        userA.ERC721LinearAutomaticDistributor as ERC721LinearAutomaticDistributor;

      await contract.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      const result = await contract.calculateReleasedAmountRounded(
        1,
        nowUnix + Math.floor(6.5 * 24 * 60 * 60) // +6.5 days
      );

      expect(result.toString()).to.equal(utils.parseEther("6"));
    });

    it("should calculate factional release amount correctly based on unit window", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA } = await setupTest();
      const contract =
        userA.ERC721LinearAutomaticDistributor as ERC721LinearAutomaticDistributor;

      await contract.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      const result = await contract.calculateReleasedAmountFractioned(
        1,
        nowUnix + Math.floor(6.5 * 24 * 60 * 60) // +6.5 days
      );

      expect(result.toString()).to.equal(utils.parseEther("6.5"));
    });
  });

  describe("Ether-based Streams", function () {
    it("should register ether-based streams", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA } = await setupTest();
      const contract =
        userA.ERC721LinearAutomaticDistributor as ERC721LinearAutomaticDistributor;

      await contract.registerStream(
        ZERO_ADDRESS,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      const result = await contract.streams(1);

      expect(result.creator).to.equal(userA.signer.address);
      expect(result.claimToken).to.equal(ZERO_ADDRESS);
      expect(result.ticketToken).to.equal(userA.TestERC721.address);
      expect(result.emissionRate).to.equal(utils.parseEther("1"));
      expect(result.claimWindowUnit).to.equal(BigNumber.from(24 * 60 * 60));
      expect(result.claimStart).to.equal(BigNumber.from(nowUnix));
      expect(result.claimEnd).to.equal(
        BigNumber.from(nowUnix + 30 * 24 * 60 * 60)
      );
    });

    it("should top-up a ether-based stream", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA } = await setupTest();
      const contract =
        userA.ERC721LinearAutomaticDistributor as ERC721LinearAutomaticDistributor;

      await contract.registerStream(
        ZERO_ADDRESS,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      await contract.topUp(1, utils.parseEther("15"), {
        value: utils.parseEther("15"),
      });

      expect(await contract.streamSupply(1)).to.equal(utils.parseEther("15"));
    });
  });

  describe.only("ERC20-based Streams", function () {
    it("should register erc20-based streams", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA } = await setupTest();
      const contract =
        userA.ERC721LinearAutomaticDistributor as ERC721LinearAutomaticDistributor;

      await contract.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      const result = await contract.streams(1);

      expect(result.creator).to.equal(userA.signer.address);
      expect(result.claimToken).to.equal(userA.TestERC20.address);
      expect(result.ticketToken).to.equal(userA.TestERC721.address);
      expect(result.emissionRate).to.equal(utils.parseEther("1"));
      expect(result.claimWindowUnit).to.equal(BigNumber.from(24 * 60 * 60));
      expect(result.claimStart).to.equal(BigNumber.from(nowUnix));
      expect(result.claimEnd).to.equal(
        BigNumber.from(nowUnix + 30 * 24 * 60 * 60)
      );
    });

    it("should top-up a erc20-based stream", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA } = await setupTest();
      const contract = userA.ERC721LinearAutomaticDistributor;

      await contract.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      await userA.TestERC20.mint(userA.signer.address, utils.parseEther("15"));
      await userA.TestERC20.approve(contract.address, utils.parseEther("15"));

      await contract.topUp(1, utils.parseEther("15"));

      expect(await contract.streamSupply(1)).to.equal(utils.parseEther("15"));
    });

    it("should top-up multiple times", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA } = await setupTest();
      const contract = userA.ERC721LinearAutomaticDistributor;

      await contract.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      await userA.TestERC20.mint(userA.signer.address, utils.parseEther("15"));
      await userA.TestERC20.approve(contract.address, utils.parseEther("15"));

      await contract.topUp(1, utils.parseEther("7"));
      await contract.topUp(1, utils.parseEther("8"));

      expect(await contract.streamSupply(1)).to.equal(utils.parseEther("15"));
    });

    it("should fail top-up for wrong stream", async function () {
      const { userA } = await setupTest();
      const contract = userA.ERC721LinearAutomaticDistributor;

      await expect(
        contract.topUp(333, utils.parseEther("7"))
      ).to.be.revertedWith("DISTRIBUTOR/WRONG_STREAM");
    });

    it("should partially claim 1 single nft", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA, userB } = await setupTest();

      await userA.ERC721LinearAutomaticDistributor.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      await userA.TestERC20.mint(userA.signer.address, utils.parseEther("15"));
      await userA.TestERC20.approve(
        userA.ERC721LinearAutomaticDistributor.address,
        utils.parseEther("15")
      );
      await userA.ERC721LinearAutomaticDistributor.topUp(
        1,
        utils.parseEther("15")
      );
      await userA.TestERC721.mintExact(userB.signer.address, 1234);

      await increaseTime(2 * 24 * 60 * 60); // 2 days

      await userB.ERC721LinearAutomaticDistributor.claim(1, 1234);

      expect(await userB.TestERC20.balanceOf(userB.signer.address)).to.equal(
        utils.parseEther("2")
      );
    });

    it("should claim remainder of unclaimed amount as new owner for 1 single nft", async function () {
      const nowUnix = Math.floor(new Date().getTime() / 1000);
      const { userA, userB, userC } = await setupTest();

      await userA.ERC721LinearAutomaticDistributor.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      await userA.TestERC20.mint(userA.signer.address, utils.parseEther("15"));
      await userA.TestERC20.approve(
        userA.ERC721LinearAutomaticDistributor.address,
        utils.parseEther("15")
      );
      await userA.ERC721LinearAutomaticDistributor.topUp(
        1,
        utils.parseEther("15")
      );
      await userA.TestERC721.mintExact(userB.signer.address, 1234);

      await increaseTime(2 * 24 * 60 * 60); // 2 days

      await userB.ERC721LinearAutomaticDistributor.claim(1, 1234);

      expect(await userB.TestERC20.balanceOf(userB.signer.address)).to.equal(
        utils.parseEther("2")
      );

      await userB.TestERC721.transferFrom(
        userB.signer.address,
        userC.signer.address,
        1234
      );

      await increaseTime(3 * 24 * 60 * 60); // 3 days

      await userC.ERC721LinearAutomaticDistributor.claim(1, 1234);

      expect(await userC.TestERC20.balanceOf(userC.signer.address)).to.equal(
        utils.parseEther("3")
      );
    });

    it("should fail to claim for wrong stream", async function () {
      const { userA } = await setupTest();
      const contract = userA.ERC721LinearAutomaticDistributor;

      await expect(contract.claim(33, 1234)).to.be.revertedWith(
        "DISTRIBUTOR/WRONG_STREAM"
      );
    });

    it("should fail to claim for non-started stream", async function () {
      const { userA } = await setupTest();
      const nowUnix = Math.floor(new Date().getTime() / 1000);

      await userA.ERC721LinearAutomaticDistributor.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix + 5 * 24 * 60 * 60, // +5 days
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      await expect(
        userA.ERC721LinearAutomaticDistributor.claim(1, 1234)
      ).to.be.revertedWith("DISTRIBUTOR/NOT_STARTED");
    });

    it("should fail to claim for empty stream", async function () {
      const { userA, userB } = await setupTest();
      const nowUnix = Math.floor(new Date().getTime() / 1000);

      await userA.ERC721LinearAutomaticDistributor.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60,
        nowUnix - 5 * 24 * 60 * 60, // -5 days
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      await userA.TestERC721.mintExact(userB.signer.address, 1234);

      await expect(
        userB.ERC721LinearAutomaticDistributor.claim(1, 1234)
      ).to.be.revertedWith("DISTRIBUTOR/STREAM_EMPTY");
    });

    it("should fail to claim when nothing to release on very first window", async function () {
      const { userA, userB } = await setupTest();
      const nowUnix = Math.floor(new Date().getTime() / 1000);

      // Register
      await userA.ERC721LinearAutomaticDistributor.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60, // daily
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      // Top-up
      await userA.TestERC20.mint(userA.signer.address, utils.parseEther("15"));
      await userA.TestERC20.approve(
        userA.ERC721LinearAutomaticDistributor.address,
        utils.parseEther("15")
      );
      await userA.ERC721LinearAutomaticDistributor.topUp(
        1,
        utils.parseEther("15")
      );

      // Mint NFT
      await userA.TestERC721.mintExact(userB.signer.address, 1234);

      // Wait
      await increaseTime(0.5 * 24 * 60 * 60); // 0.5 day

      await expect(
        userB.ERC721LinearAutomaticDistributor.claim(1, 1234)
      ).to.be.revertedWith("DISTRIBUTOR/NOTHING_TO_CLAIM");
    });

    it("should fail to claim when too early according to window unit", async function () {
      const { userA, userB } = await setupTest();
      const nowUnix = Math.floor(new Date().getTime() / 1000);

      // Register
      await userA.ERC721LinearAutomaticDistributor.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60, // daily
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      // Top-up
      await userA.TestERC20.mint(userA.signer.address, utils.parseEther("15"));
      await userA.TestERC20.approve(
        userA.ERC721LinearAutomaticDistributor.address,
        utils.parseEther("15")
      );
      await userA.ERC721LinearAutomaticDistributor.topUp(
        1,
        utils.parseEther("15")
      );

      // Mint NFT
      await userA.TestERC721.mintExact(userB.signer.address, 1234);

      // Wait
      await increaseTime(1 * 24 * 60 * 60); // 1 day

      // Claim
      await userB.ERC721LinearAutomaticDistributor.claim(1, 1234);

      // Wait
      await increaseTime(0.5 * 24 * 60 * 60); // 0.5 day

      await expect(
        userB.ERC721LinearAutomaticDistributor.claim(1, 1234)
      ).to.be.revertedWith("DISTRIBUTOR/TOO_EARLY");
    });

    it("should fail to claim when stream is depleted", async function () {
      const { userA, userB } = await setupTest();
      const nowUnix = Math.floor(new Date().getTime() / 1000);

      // Register
      await userA.ERC721LinearAutomaticDistributor.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60, // daily
        nowUnix,
        nowUnix + 30 * 24 * 60 * 60 // +30 days
      );

      // Top-up
      await userA.TestERC20.mint(userA.signer.address, utils.parseEther("6"));
      await userA.TestERC20.approve(
        userA.ERC721LinearAutomaticDistributor.address,
        utils.parseEther("6")
      );
      await userA.ERC721LinearAutomaticDistributor.topUp(
        1,
        utils.parseEther("6")
      );

      // Mint NFT
      await userA.TestERC721.mintExact(userB.signer.address, 1234);

      // Wait & Claim
      await increaseTime(3 * 24 * 60 * 60); // 3 day
      await userB.ERC721LinearAutomaticDistributor.claim(1, 1234);
      await increaseTime(2 * 24 * 60 * 60); // 2 day
      await userB.ERC721LinearAutomaticDistributor.claim(1, 1234);

      // Wait
      await increaseTime(8 * 24 * 60 * 60); // 8 day

      await expect(
        userB.ERC721LinearAutomaticDistributor.claim(1, 1234)
      ).to.be.revertedWith("DISTRIBUTOR/STREAM_DEPLETED");
    });

    it("should claim when stream is ended even if claimed long after end time", async function () {
      const { userA, userB } = await setupTest();
      const nowUnix = Math.floor(new Date().getTime() / 1000);

      // Register
      await userA.ERC721LinearAutomaticDistributor.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("1"),
        24 * 60 * 60, // daily
        nowUnix,
        nowUnix + 6 * 24 * 60 * 60 // +6 days
      );

      // Top-up
      await userA.TestERC20.mint(userA.signer.address, utils.parseEther("6"));
      await userA.TestERC20.approve(
        userA.ERC721LinearAutomaticDistributor.address,
        utils.parseEther("6")
      );
      await userA.ERC721LinearAutomaticDistributor.topUp(
        1,
        utils.parseEther("6")
      );

      // Mint NFT
      await userA.TestERC721.mintExact(userB.signer.address, 1234);

      // Wait & Claim
      await increaseTime(3 * 24 * 60 * 60); // 3 day
      await userB.ERC721LinearAutomaticDistributor.claim(1, 1234);
      await increaseTime(2 * 24 * 60 * 60); // 2 day
      await userB.ERC721LinearAutomaticDistributor.claim(1, 1234);

      // Wait
      await increaseTime(8 * 24 * 60 * 60); // 8 day

      // Claim
      await userB.ERC721LinearAutomaticDistributor.claim(1, 1234);

      expect(await userB.TestERC20.balanceOf(userB.signer.address)).to.equal(
        utils.parseEther("6")
      );
    });

    it("should claim in bulk when stream is ended even if claimed long after end time", async function () {
      const { userA, userB } = await setupTest();
      const nowUnix = Math.floor(new Date().getTime() / 1000);

      // Register
      await userA.ERC721LinearAutomaticDistributor.registerStream(
        userA.TestERC20.address,
        userA.TestERC721.address,
        utils.parseEther("2"),
        24 * 60 * 60, // daily
        nowUnix,
        nowUnix + 6 * 24 * 60 * 60 // +6 days
      );

      // Top-up
      await userA.TestERC20.mint(userA.signer.address, utils.parseEther("24"));
      await userA.TestERC20.approve(
        userA.ERC721LinearAutomaticDistributor.address,
        utils.parseEther("24")
      );
      await userA.ERC721LinearAutomaticDistributor.topUp(
        1,
        utils.parseEther("24")
      );

      // Mint NFT
      await userA.TestERC721.mintExact(userB.signer.address, 1234);
      await userA.TestERC721.mintExact(userB.signer.address, 5678);

      // Wait & Claim
      await increaseTime(3 * 24 * 60 * 60); // 3 day
      await userB.ERC721LinearAutomaticDistributor.claimBulk(1, [1234, 5678]);
      await increaseTime(2 * 24 * 60 * 60); // 2 day
      await userB.ERC721LinearAutomaticDistributor.claimBulk(1, [1234, 5678]);

      // Wait
      await increaseTime(8 * 24 * 60 * 60); // 8 day

      // Claim
      await userB.ERC721LinearAutomaticDistributor.claimBulk(1, [1234, 5678]);

      expect(await userB.TestERC20.balanceOf(userB.signer.address)).to.equal(
        utils.parseEther("24")
      );
    });
  });
});
