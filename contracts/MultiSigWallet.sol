// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./token.sol";

contract MultiSigWallet {
    event Response(bool success, bytes data);
    event Deposit(address indexed sender, uint amount, uint balance);
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data,
        address token
    );
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numConfirmations;
        address token;
    }

    struct Token {
        address addr;
        string name;
        string symbol;
        bool executed;
        uint numConfirmations;
    }

    struct PendingOwner {
        address addr;
        bool executed;
        uint numConfirmations;
    }

    PendingOwner[] public pendingOwners;
    Token[] public tokens;
    Transaction[] public transactions;

    mapping(address => bool) public haveToken;
    mapping(string => address) public mapSymbolAddr;

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;
    mapping(uint => mapping(address => bool)) public isTokenConfirmed;
    mapping(uint => mapping(address => bool)) public isOwnerConfirmed;

    // Check transaction
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    // Check token
    modifier tokenExists(uint _tokenIndex) {
        require(_tokenIndex < tokens.length, "token does not exist");
        _;
    }

    modifier tokenNotExecuted(uint _tokenIndex) {
        require(!tokens[_tokenIndex].executed, "token already executed");
        _;
    }

    modifier tokenNotConfirmed(uint _tokenIndex) {
        require(!isTokenConfirmed[_tokenIndex][msg.sender], "token already confirmed");
        _;
    }

    // Check Owner
    modifier ownerExists(uint _ownerIndex) {
        require(_ownerIndex < pendingOwners.length, "owner does not exist");
        _;
    }

    modifier ownerNotExecuted(uint _ownerIndex) {
        require(!pendingOwners[_ownerIndex].executed, "owner already executed");
        _;
    }

    modifier ownerNotConfirmed(uint _ownerIndex) {
        require(!isOwnerConfirmed[_ownerIndex][msg.sender], "owner already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
            _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        // for (uint i = 0; i < _tokens.length; i++) {
        //     address token = _tokens[i];

        //     require(token != address(0), "invalid token");
        //     require(!haveToken[token], "owner not unique");

        //     haveToken[token] = true;
        //     tokens.push(token);
        // }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }


    // addOwner
    function addOwner(address owner) public onlyOwner {
        for (uint i = 0; owners.length; i++) {
            require(owner == owners[i], "address already exists")
            }
            pendingOwners.push(PendingOwner({
        addr: owner,
        executed: false,
        numConfirmations: 0
        }));
        }

    function confirmOwner(uint _tokenIndex)
    public
    onlyOwner
    tokenExists(_tokenIndex)
    tokenNotExecuted(_tokenIndex)
    tokenNotConfirmed(_tokenIndex)
    {
    Token storage token = tokens[_tokenIndex];
    token.numConfirmations += 1;
    isTokenConfirmed[_tokenIndex][msg.sender] = true;

    emit ConfirmTransaction(msg.sender, _tokenIndex);
    }

    function executeAddToken(uint _tokenIndex)
    public
    onlyOwner
    txExists(_tokenIndex)
    notExecuted(_tokenIndex)
    {
    Token storage token = tokens[_tokenIndex];

    require(
    token.numConfirmations >= numConfirmationsRequired,
    "cannot add token"
    );

    token.executed = true;
    }

    function revokeToken(uint _tokenIndex)
    public
    onlyOwner
    txExists(_tokenIndex)
    notExecuted(_tokenIndex)
    {
    Token storage token = tokens[_tokenIndex];

    require(isTokenConfirmed[_tokenIndex][msg.sender], "token not confirmed");

    token.numConfirmations -= 1;
    isTokenConfirmed[_tokenIndex][msg.sender] = false;

    emit RevokeConfirmation(msg.sender, _tokenIndex);
    }

        //token
    function createToken(string memory _name, string memory _symbol, uint256 _totalSuply) public {
    HotCoinERC20 token = new HotCoinERC20(_totalSuply, _name, _symbol);
    tokens.push(Token({
    addr: address(token),
    name: _name,
    symbol: _symbol,
    executed: false,
    numConfirmations: 0
    }));
    }

    function confirmToken(uint _tokenIndex)
    public
    onlyOwner
    tokenExists(_tokenIndex)
    tokenNotExecuted(_tokenIndex)
    tokenNotConfirmed(_tokenIndex)
    {
    Token storage token = tokens[_tokenIndex];
    token.numConfirmations += 1;
    isTokenConfirmed[_tokenIndex][msg.sender] = true;

    emit ConfirmTransaction(msg.sender, _tokenIndex);
    }

    function executeAddToken(uint _tokenIndex)
    public
    onlyOwner
    txExists(_tokenIndex)
    notExecuted(_tokenIndex)
    {
    Token storage token = tokens[_tokenIndex];

    require(
    token.numConfirmations >= numConfirmationsRequired,
    "cannot add token"
    );

    token.executed = true;
    }

    function revokeToken(uint _tokenIndex)
    public
    onlyOwner
    txExists(_tokenIndex)
    notExecuted(_tokenIndex)
    {
    Token storage token = tokens[_tokenIndex];

    require(isTokenConfirmed[_tokenIndex][msg.sender], "token not confirmed");

    token.numConfirmations -= 1;
    isTokenConfirmed[_tokenIndex][msg.sender] = false;

    emit RevokeConfirmation(msg.sender, _tokenIndex);
    }

        // transaction
    function submitTransaction(
    address _to,
    uint _value,
    bytes memory _data,
    address _token
    ) public onlyOwner {
    uint txIndex = transactions.length;

    transactions.push(
    Transaction({
    to: _to,
    value: _value,
    data: _data,
    executed: false,
    numConfirmations: 0,
    token: _token
    })
    );

    emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data, _token);
    }

    function confirmTransaction(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    notConfirmed(_txIndex)
    {
    Transaction storage transaction = transactions[_txIndex];
    transaction.numConfirmations += 1;
    isConfirmed[_txIndex][msg.sender] = true;

    emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    {
    Transaction storage transaction = transactions[_txIndex];

    require(
    transaction.numConfirmations >= numConfirmationsRequired,
    "cannot execute tx"
    );

    transaction.executed = true;

    (bool success, ) = transaction.token.call(
    abi.encodeWithSignature("transfer(address, uint256)", transaction.to, transaction.value)
    );
    require(success, "tx failed");

    emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint _txIndex)
    public
    onlyOwner
    txExists(_txIndex)
    notExecuted(_txIndex)
    {
    Transaction storage transaction = transactions[_txIndex];

    require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

    transaction.numConfirmations -= 1;
    isConfirmed[_txIndex][msg.sender] = false;

    emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
    return owners;
    }

    function getTransactionCount() public view returns (uint) {
    return transactions.length;
    }

    function getTokenLength() public view returns (uint) {
    return tokens.length;
    }

    function getTokenAddress(uint _tokenIndex) public view returns (address) {
    return tokens[_tokenIndex].addr;
    }

    function getTokenInfo(address _token) external view returns (bool success, string memory _name, string memory _symbol) {
    (success, _name, _symbol) = HotCoinERC20(_token).getTokenInfo();
    require(success, "Error Token");
    }

    function getTransaction(uint _txIndex)
    public
    view
    returns (
    address to,
    uint value,
    bytes memory data,
    bool executed,
    uint numConfirmations,
    address token
    )
    {
    Transaction storage transaction = transactions[_txIndex];

    return (
    transaction.to,
    transaction.value,
    transaction.data,
    transaction.executed,
    transaction.numConfirmations,
    transaction.token
    );
    }
    }
