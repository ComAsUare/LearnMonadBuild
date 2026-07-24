// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ProposalVote — DAO 治理提案投票合约
/// @notice 支持多次提案、委托投票权重、投票门槛
interface IGovernanceToken {
    function balanceOf(address account) external view returns (uint256);
    function getVotes(address account) external view returns (uint256);
    function delegate(address delegatee) external;
}

contract ProposalVote {
    // ============================================================
    //  Structs
    // ============================================================

    /// @notice 单次提案的完整状态
    /// @dev mapping 在 struct 中仅允许用于 storage 引用，不可作为 memory 参数传递
    struct Proposal {
        uint256 proposalId;
        address proposer;
        string  proposalIntent;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => bool) hasVoted;
        bool    executed;
    }

    // ============================================================
    //  State Variables
    // ============================================================

    IGovernanceToken public immutable governanceToken;

    /// @notice 发起提案所需的最低投票权重
    uint256 public proposalThreshold;

    /// @notice 提案总数，同时用作自增 proposalId
    uint256 public proposalCount;

    /// @notice 按 proposalId 存储所有提案
    mapping(uint256 => Proposal) public proposals;

    // ============================================================
    //  Events
    // ============================================================

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string proposalIntent,
        uint256 startTime,
        uint256 endTime
    );

    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 weight
    );

    event ProposalFinalized(
        uint256 indexed proposalId,
        uint256 forVotes,
        uint256 againstVotes,
        bool passed
    );

    // ============================================================
    //  Errors (gas-efficient, Solidity 0.8.4+)
    // ============================================================

    error BelowProposalThreshold(address sender, uint256 votes, uint256 required);
    error ProposalNotExist(uint256 proposalId);
    error VotingNotActive(uint256 proposalId, uint256 currentTime, uint256 startTime, uint256 endTime);
    error AlreadyVoted(uint256 proposalId, address voter);
    error VotingNotEnded(uint256 proposalId, uint256 currentTime, uint256 endTime);
    error AlreadyFinalized(uint256 proposalId);
    error InvalidGovernanceTokenAddress();

    // ============================================================
    //  Constructor
    // ============================================================

    constructor(address _governanceToken, uint256 _proposalThreshold) {
        if (_governanceToken == address(0)) {
            revert InvalidGovernanceTokenAddress();
        }
        governanceToken = IGovernanceToken(_governanceToken);
        proposalThreshold = _proposalThreshold;
    }

    // ============================================================
    //  Core Functions
    // ============================================================

    /// @notice 创建新提案
    /// @param _proposalIntent  提案内容描述
    /// @param _votingDuration  投票持续时间（秒）
    function createProposal(
        string calldata _proposalIntent,
        uint256 _votingDuration
    ) external {
        uint256 votes = governanceToken.getVotes(msg.sender);
        if (votes < proposalThreshold) {
            revert BelowProposalThreshold(msg.sender, votes, proposalThreshold);
        }

        uint256 newId = ++proposalCount;

        Proposal storage p = proposals[newId];
        p.proposalId      = newId;
        p.proposer        = msg.sender;
        p.proposalIntent  = _proposalIntent;
        p.startTime       = block.timestamp;
        p.endTime         = block.timestamp + _votingDuration;

        emit ProposalCreated(newId, msg.sender, _proposalIntent, p.startTime, p.endTime);
    }

    /// @notice 对提案投赞成/反对票
    /// @param _proposalId  提案 ID
    /// @param _support     true = 赞成, false = 反对
    function castVote(uint256 _proposalId, bool _support) external {
        Proposal storage p = proposals[_proposalId];
        if (p.proposalId == 0) {
            revert ProposalNotExist(_proposalId);
        }
        if (block.timestamp < p.startTime || block.timestamp > p.endTime) {
            revert VotingNotActive(_proposalId, block.timestamp, p.startTime, p.endTime);
        }
        if (p.hasVoted[msg.sender]) {
            revert AlreadyVoted(_proposalId, msg.sender);
        }

        p.hasVoted[msg.sender] = true;
        uint256 weight = governanceToken.getVotes(msg.sender);

        if (_support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }

        emit VoteCast(_proposalId, msg.sender, _support, weight);
    }

    /// @notice 投票截止后，结束提案并判定结果
    /// @param _proposalId  提案 ID
    function finalizeProposal(uint256 _proposalId) external {
        Proposal storage p = proposals[_proposalId];
        if (p.proposalId == 0) {
            revert ProposalNotExist(_proposalId);
        }
        if (block.timestamp <= p.endTime) {
            revert VotingNotEnded(_proposalId, block.timestamp, p.endTime);
        }
        if (p.executed) {
            revert AlreadyFinalized(_proposalId);
        }

        p.executed = true;
        bool passed = p.forVotes > p.againstVotes;

        emit ProposalFinalized(_proposalId, p.forVotes, p.againstVotes, passed);
    }

    // ============================================================
    //  View / Query
    // ============================================================

    /// @notice 查询某地址在某提案中是否已投票
    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        return proposals[_proposalId].hasVoted[_voter];
    }

    /// @notice 获取提案基本信息（不含 mapping）
    function getProposalSummary(uint256 _proposalId)
        external
        view
        returns (
            uint256 proposalId,
            address proposer,
            string memory proposalIntent,
            uint256 startTime,
            uint256 endTime,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (
            p.proposalId,
            p.proposer,
            p.proposalIntent,
            p.startTime,
            p.endTime,
            p.forVotes,
            p.againstVotes,
            p.executed
        );
    }

    // ============================================================
    //  Admin
    // ============================================================

    /// @notice 更新提案门槛（仅治理可调用 — 示例保留，可接入 onlyOwner / onlyGovernance）
    function setProposalThreshold(uint256 _newThreshold) external {
        // TODO: add access control (e.g. onlyOwner / onlyGovernance)
        proposalThreshold = _newThreshold;
    }
}
