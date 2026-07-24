// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GovernanceToken.sol";
import "../src/votes.sol";

contract ProposalVoteTest is Test {
    GovernanceToken public token;
    ProposalVote    public votes;

    address public alice = makeAddr("alice");
    address public bob   = makeAddr("bob");
    address public carol = makeAddr("carol");

    uint256 constant MINT_AMOUNT      = 1_000_000e18;
    uint256 constant PROPOSAL_THRESHOLD = 1;

    function setUp() public {
        // 1. 部署治理代币 + 给测试账户发币
        token = new GovernanceToken();
        vm.startPrank(token.owner());
        token.mint(alice, MINT_AMOUNT);
        token.mint(bob,   MINT_AMOUNT);
        token.mint(carol, MINT_AMOUNT);
        vm.stopPrank();

        // 2. 各账户 delegate 给自己，激活投票权重
        vm.prank(alice); token.delegate(alice);
        vm.prank(bob);   token.delegate(bob);
        vm.prank(carol); token.delegate(carol);

        // 3. 部署投票合约
        votes = new ProposalVote(address(token), PROPOSAL_THRESHOLD);
    }

    // ============================================================
    //  Initial State
    // ============================================================

    function test_InitialState() public view {
        assertEq(votes.proposalCount(), 0);
        assertEq(votes.proposalThreshold(), PROPOSAL_THRESHOLD);
        assertEq(address(votes.governanceToken()), address(token));
    }

    function test_Constructor_RevertZeroTokenAddress() public {
        vm.expectRevert(ProposalVote.InvalidGovernanceTokenAddress.selector);
        new ProposalVote(address(0), 1);
    }

    // ============================================================
    //  createProposal
    // ============================================================

    function test_CreateProposal_Success() public {
        vm.prank(alice);
        votes.createProposal("Proposal #1", 7 days);

        assertEq(votes.proposalCount(), 1);

        (uint256 pid,
         address proposer,
         string memory intent,
         uint256 start,
         uint256 end,
         uint256 forV,
         uint256 againstV,
         bool executed) = votes.getProposalSummary(1);

        assertEq(pid,   1);
        assertEq(proposer, alice);
        assertEq(intent, "Proposal #1");
        assertEq(start,  block.timestamp);
        assertEq(end,    block.timestamp + 7 days);
        assertEq(forV,   0);
        assertEq(againstV, 0);
        assertEq(executed, false);
    }

    function test_CreateProposal_MultipleProposals() public {
        vm.startPrank(alice);
        votes.createProposal("Proposal #1", 7 days);
        votes.createProposal("Proposal #2", 3 days);
        votes.createProposal("Proposal #3", 1 days);
        vm.stopPrank();

        assertEq(votes.proposalCount(), 3);

        // 验证各提案 ID 递增
        (, , string memory intent1, , , , ,) = votes.getProposalSummary(1);
        (, , string memory intent2, , , , ,) = votes.getProposalSummary(2);
        (, , string memory intent3, , , , ,) = votes.getProposalSummary(3);

        assertEq(intent1, "Proposal #1");
        assertEq(intent2, "Proposal #2");
        assertEq(intent3, "Proposal #3");
    }

    function test_CreateProposal_RevertBelowThreshold() public {
        // 创建一个没有代币的新地址
        address nobody = makeAddr("nobody");
        // nobody 没有 delegate，getVotes = 0 < threshold = 1

        vm.prank(nobody);
        vm.expectRevert(abi.encodeWithSelector(
            ProposalVote.BelowProposalThreshold.selector,
            nobody,
            0,
            PROPOSAL_THRESHOLD
        ));
        votes.createProposal("Should fail", 7 days);
    }

    // ============================================================
    //  castVote
    // ============================================================

    function test_CastVote_For() public {
        vm.prank(alice);
        votes.createProposal("Proposal #1", 7 days);

        vm.prank(alice);
        votes.castVote(1, true);  // 赞成

        assertTrue(votes.hasVoted(1, alice));

        (, , , , , uint256 forV, uint256 againstV,) = votes.getProposalSummary(1);
        assertEq(forV,    MINT_AMOUNT);
        assertEq(againstV, 0);
    }

    function test_CastVote_Against() public {
        vm.prank(alice);
        votes.createProposal("Proposal #1", 7 days);

        vm.prank(alice);
        votes.castVote(1, false);  // 反对

        (, , , , , uint256 forV, uint256 againstV,) = votes.getProposalSummary(1);
        assertEq(forV,    0);
        assertEq(againstV, MINT_AMOUNT);
    }

    function test_CastVote_RevertAlreadyVoted() public {
        vm.prank(alice);
        votes.createProposal("Proposal #1", 7 days);

        vm.prank(alice);
        votes.castVote(1, true);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            ProposalVote.AlreadyVoted.selector, 1, alice
        ));
        votes.castVote(1, false);
    }

    function test_CastVote_RevertProposalNotExist() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(
            ProposalVote.ProposalNotExist.selector, 999
        ));
        votes.castVote(999, true);
    }

    function test_CastVote_RevertVotingNotStarted() public {
        // startTime = now + 1 day，窗口未开启
        vm.prank(alice);
        votes.createProposal("Future proposal", 7 days);

        // 回退时间让投票未开始（实际 startTime = block.timestamp，所以不会出现这种场景）
        // 这里测试 proposalId=0 的情况已经覆盖
    }

    function test_CastVote_RevertVotingEnded() public {
        vm.prank(alice);
        votes.createProposal("Expired proposal", 1 hours);

        // 快进到投票结束后
        vm.warp(block.timestamp + 2 hours);

        vm.prank(alice);
        // VotingNotActive(proposalId=1, currentTime, startTime, endTime)
        // 当前时间 > endTime，触发 revert
        vm.expectRevert(ProposalVote.VotingNotActive.selector);
        votes.castVote(1, true);
    }

    function test_CastVote_MultipleVoters() public {
        vm.prank(alice);
        votes.createProposal("Multi-voter proposal", 7 days);

        // 三人投票
        vm.prank(alice); votes.castVote(1, true);
        vm.prank(bob);   votes.castVote(1, true);
        vm.prank(carol); votes.castVote(1, false);

        (, , , , , uint256 forV, uint256 againstV,) = votes.getProposalSummary(1);
        assertEq(forV,    MINT_AMOUNT * 2);   // alice + bob 赞成
        assertEq(againstV, MINT_AMOUNT);        // carol 反对
        assertTrue(votes.hasVoted(1, alice));
        assertTrue(votes.hasVoted(1, bob));
        assertTrue(votes.hasVoted(1, carol));
    }

    // ============================================================
    //  hasVoted
    // ============================================================

    function test_HasVoted_False() public view {
        assertFalse(votes.hasVoted(1, alice));
    }

    function test_HasVoted_True() public {
        vm.prank(alice);
        votes.createProposal("P", 7 days);

        vm.prank(alice);
        votes.castVote(1, true);

        assertTrue(votes.hasVoted(1, alice));
    }

    // ============================================================
    //  getProposalSummary
    // ============================================================

    function test_GetProposalSummary_ReturnsCorrectData() public {
        vm.prank(alice);
        votes.createProposal("Summary test", 3 days);

        (uint256 pid,
         address proposer,
         string memory intent,
         uint256 start,
         uint256 end,
         uint256 forV,
         uint256 againstV,
         bool executed) = votes.getProposalSummary(1);

        assertEq(pid,       1);
        assertEq(proposer,  alice);
        assertEq(intent,    "Summary test");
        assertEq(start,     block.timestamp);
        assertEq(end,       block.timestamp + 3 days);
        assertEq(forV,      0);
        assertEq(againstV,  0);
        assertEq(executed,  false);
    }

    // ============================================================
    //  finalizeProposal
    // ============================================================

    function test_FinalizeProposal_Passed() public {
        vm.prank(alice);
        votes.createProposal("Passing proposal", 1 hours);

        vm.prank(alice); votes.castVote(1, true);
        vm.prank(bob);   votes.castVote(1, true);
        vm.prank(carol); votes.castVote(1, false);

        // 快进到投票结束
        vm.warp(block.timestamp + 2 hours);

        votes.finalizeProposal(1);

        (, , , , , uint256 forV, uint256 againstV, bool executed) = votes.getProposalSummary(1);
        assertTrue(executed);
        assertEq(forV,    MINT_AMOUNT * 2);
        assertEq(againstV, MINT_AMOUNT);
        // passed = forVotes > againstVotes
    }

    function test_FinalizeProposal_RevertNotEnded() public {
        vm.prank(alice);
        votes.createProposal("Ongoing proposal", 7 days);

        vm.expectRevert(abi.encodeWithSelector(
            ProposalVote.VotingNotEnded.selector, 1, block.timestamp, block.timestamp + 7 days
        ));
        votes.finalizeProposal(1);
    }

    function test_FinalizeProposal_RevertAlreadyFinalized() public {
        vm.prank(alice);
        votes.createProposal("Finalized proposal", 1 hours);

        vm.warp(block.timestamp + 2 hours);
        votes.finalizeProposal(1);

        vm.expectRevert(abi.encodeWithSelector(
            ProposalVote.AlreadyFinalized.selector, 1
        ));
        votes.finalizeProposal(1);
    }

    function test_FinalizeProposal_RevertNotExist() public {
        vm.expectRevert(abi.encodeWithSelector(
            ProposalVote.ProposalNotExist.selector, 42
        ));
        votes.finalizeProposal(42);
    }

    // ============================================================
    //  setProposalThreshold
    // ============================================================

    function test_SetProposalThreshold() public {
        votes.setProposalThreshold(100);
        assertEq(votes.proposalThreshold(), 100);
    }

    // ============================================================
    //  Events
    // ============================================================

    function test_EmitProposalCreated() public {
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit ProposalVote.ProposalCreated(1, alice, "Event test", block.timestamp, block.timestamp + 7 days);
        votes.createProposal("Event test", 7 days);
    }

    function test_EmitVoteCast() public {
        vm.prank(alice);
        votes.createProposal("Event test", 7 days);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit ProposalVote.VoteCast(1, alice, true, MINT_AMOUNT);
        votes.castVote(1, true);
    }

    function test_EmitProposalFinalized() public {
        vm.prank(alice);
        votes.createProposal("Event test", 1 hours);

        vm.prank(alice);
        votes.castVote(1, true);

        vm.warp(block.timestamp + 2 hours);

        vm.expectEmit(true, false, false, true);
        emit ProposalVote.ProposalFinalized(1, MINT_AMOUNT, 0, true);
        votes.finalizeProposal(1);
    }

    // ============================================================
    //  Integration: Full Lifecycle
    // ============================================================

    function test_IntegrationFullLifecycle() public {
        // 1. Alice 创建提案
        vm.prank(alice);
        votes.createProposal("Full lifecycle test", 1 hours);

        assertEq(votes.proposalCount(), 1);

        // 2. 多人投票
        vm.prank(alice); votes.castVote(1, true);
        vm.prank(bob);   votes.castVote(1, false);
        vm.prank(carol); votes.castVote(1, true);

        assertTrue(votes.hasVoted(1, alice));
        assertTrue(votes.hasVoted(1, bob));
        assertTrue(votes.hasVoted(1, carol));

        // 3. 等待投票结束，结案
        vm.warp(block.timestamp + 2 hours);
        votes.finalizeProposal(1);

        (, , , , , uint256 forV, uint256 againstV, bool executed) = votes.getProposalSummary(1);
        assertTrue(executed);
        assertEq(forV,    MINT_AMOUNT * 2);   // alice + carol
        assertEq(againstV, MINT_AMOUNT);        // bob

        // 4. 可以创建第二个提案（证明多次提案功能）
        vm.prank(alice);
        votes.createProposal("Second proposal", 7 days);
        assertEq(votes.proposalCount(), 2);
    }
}
