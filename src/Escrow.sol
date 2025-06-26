// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;



contract Escrow {
    enum EscrowStatus { Created, Funded, Released, Refunded, Disputed, Resolved }

    struct EscrowDetails {
        address buyer;
        address seller;
        address arbiter;
        uint256 amount;
        uint256 deadline;
        string description;
        EscrowStatus status;
        bool isDisputed;
    }

    uint256 public escrowCounter;
    mapping(uint256 => EscrowDetails) public escrows;

    event EscrowCreated(uint256 escrowId, address indexed buyer, address indexed seller, uint256 amount, uint256 deadline, string description);
    event Funded(uint256 escrowId, address indexed buyer, uint256 amount);
    event Released(uint256 escrowId, address indexed seller);
    event Refunded(uint256 escrowId, address indexed buyer);
    event DisputeResolved(uint256 escrowId, address indexed arbiter, bool releasedToSeller);

    modifier onlyBuyer(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].buyer, "Only buyer can call this");
        _;
    }

    modifier onlySeller(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].seller, "Only seller can call this");
        _;
    }

    modifier onlyArbiter(uint256 escrowId) {
        require(msg.sender == escrows[escrowId].arbiter, "Only arbiter can call this");
        _;
    }

    modifier inStatus(uint256 escrowId, EscrowStatus requiredStatus) {
        require(escrows[escrowId].status == requiredStatus, "Invalid escrow status");
        _;
    }

    function createEscrow(
        address seller,
        address arbiter,
        uint256 amount,
        uint256 deadline,
        string memory description
    ) external returns (uint256 escrowId) {
        require(seller != address(0) && arbiter != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than 0");

        escrowId = ++escrowCounter;
        escrows[escrowId] = EscrowDetails({
            buyer: msg.sender,
            seller: seller,
            arbiter: arbiter,
            amount: amount,
            deadline: deadline,
            description: description,
            status: EscrowStatus.Created,
            isDisputed: false
        });

        emit EscrowCreated(escrowId, msg.sender, seller, amount, deadline, description);
    }

    function fundEscrow(uint256 escrowId)
        external
        payable
        onlyBuyer(escrowId)
        inStatus(escrowId, EscrowStatus.Created)
    {
        EscrowDetails storage esc = escrows[escrowId];
        require(msg.value == esc.amount, "Incorrect funding amount");

        esc.status = EscrowStatus.Funded;
        emit Funded(escrowId, msg.sender, msg.value);
    }

    function releaseFunds(uint256 escrowId)
        external
        onlySeller(escrowId)
        inStatus(escrowId, EscrowStatus.Funded)
    {
        EscrowDetails storage esc = escrows[escrowId];
        esc.status = EscrowStatus.Released;
        payable(esc.seller).transfer(esc.amount);

        emit Released(escrowId, esc.seller);
    }

    function requestRefund(uint256 escrowId)
    external
    onlyBuyer(escrowId)
    inStatus(escrowId, EscrowStatus.Funded)
{
    EscrowDetails storage esc = escrows[escrowId];
    
    require(block.timestamp >= esc.deadline, "Deadline not passed");
    
    esc.status = EscrowStatus.Refunded;
    payable(esc.buyer).transfer(esc.amount);

    emit Refunded(escrowId, esc.buyer);
}

    function resolveDispute(uint256 escrowId, bool releaseToSeller)
        external
        onlyArbiter(escrowId)
        inStatus(escrowId, EscrowStatus.Funded)
    {
        EscrowDetails storage esc = escrows[escrowId];
        esc.status = EscrowStatus.Resolved;
        esc.isDisputed = true;

        if (releaseToSeller) {
            payable(esc.seller).transfer(esc.amount);
        } else {
            payable(esc.buyer).transfer(esc.amount);
        }

        emit DisputeResolved(escrowId, msg.sender, releaseToSeller);
    }

    function getEscrowDetails(uint256 escrowId)
        external
        view
        returns (EscrowDetails memory)
    {
        return escrows[escrowId];
    }
}
