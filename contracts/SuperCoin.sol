// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract SuperCoin {
    // Contract constructs

    enum AccountType {
        UNREGISTERED,
        CONSUMER,
        BUSINESS,
        OWNER
    }

    struct Account {
        uint balance;
        AccountType accountType; // has default value unregistered
    }

    // state variables

    address immutable OWNER_ADDRESS;
    mapping(address => Account) accounts;

    // errors

    /// Funds are insuffient in the senders account.
    /// needed `requested` but only `available` is available
    /// @param requested request transfer amount
    /// @param available available amount in the senders account
    error InsufficientFunds(uint requested, uint available);

    /// Only requestor with `validAuthority` can do this action
    /// @param validAuthority authority by whom action is allowed only
    /// @param senderAuthority authority of the requester
    error UnAuthorized(AccountType validAuthority, AccountType senderAuthority);

    /// Only recipient with `validAuthority` can get this transaction money
    /// @param validAuthority authority to whom transaction is allowed only
    /// @param recieverAuthority authority of the recipient
    error InValidRecipient(
        AccountType validAuthority,
        AccountType recieverAuthority
    );

    /// Invalid regisration
    /// User already has an account with `existingAuthority`
    /// @param existingAuthority existing authority of the user
    error InValidRegistration(AccountType existingAuthority);

    // events

    /// event emittend when a transaction of `amount` supercoin is done
    /// from `sender` account to `reciever` account
    /// @param sender sender account
    /// @param receiver reciever account
    /// @param amount amount transferred
    event TransanctionComplete(address sender, address receiver, uint amount);

    /// event emitted when a new member is registered at address `address`
    /// with authority `authority`
    /// @param memberAddress address of the new joinee
    /// @param authority authority of the new joinee
    event MemberRegistered(address memberAddress, AccountType authority);

    // modifiers

    modifier checkFunds(address sender, uint request) {
        if (accounts[sender].balance < request) {
            revert InsufficientFunds(request, accounts[sender].balance);
        }
        _;
    }

    modifier checkAccess(AccountType allowedAuthority) {
        if (accounts[msg.sender].accountType != allowedAuthority) {
            revert UnAuthorized(
                allowedAuthority,
                accounts[msg.sender].accountType
            );
        }
        _;
    }

    // internal functions

    function _transfer(
        address receiver,
        address sender,
        uint amount
    ) internal checkFunds(sender, amount) {
        accounts[sender].balance -= amount;
        accounts[receiver].balance += amount;
        emit TransanctionComplete(sender, receiver, amount);
    }

    // public functions

    constructor() {
        OWNER_ADDRESS = msg.sender;
        Account storage onwerAccount = accounts[OWNER_ADDRESS];
        onwerAccount.balance = 0;
        onwerAccount.accountType = AccountType.OWNER;
    }

    // public consumer functions

    function consumerPayment(
        uint amount
    ) public checkAccess(AccountType.CONSUMER) {
        _transfer(OWNER_ADDRESS, msg.sender, amount);
    }

    function purchaseCoupon() public checkAccess(AccountType.CONSUMER) {
        // create a coupon entity and assign it to consumer and reduce coupons cost
    }

    // public business functions

    function redeemTokens(uint amount) public {
        //  better flow requires confirmation of both the parties
    }

    // public owner functions

    function createCoupons() public checkAccess(AccountType.OWNER) {
        // create coupons and transfer it to brands
    }

    function registerMember(
        address memberAddress,
        AccountType accountType
    ) public checkAccess(AccountType.OWNER) {
        if (accounts[memberAddress].accountType != AccountType.UNREGISTERED) {
            revert InValidRegistration(accounts[memberAddress].accountType);
        }
        Account storage memberAccount = accounts[memberAddress];
        memberAccount.balance = 0;
        memberAccount.accountType = accountType;
        emit MemberRegistered(memberAddress, accountType);
    }

    function payBusiness(
        address business,
        uint amount
    ) public checkAccess(AccountType.OWNER) {
        if (accounts[business].accountType != AccountType.BUSINESS) {
            revert InValidRecipient(
                AccountType.BUSINESS,
                accounts[business].accountType
            );
        }

        accounts[business].balance += amount;
        accounts[OWNER_ADDRESS].balance -= amount;
    }

    function mintTokens(
        uint amount
    ) public checkAccess(AccountType.OWNER) returns (uint) {
        accounts[msg.sender].balance += amount;
        return accounts[msg.sender].balance;
    }
}
