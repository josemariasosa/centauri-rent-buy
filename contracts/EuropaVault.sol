// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";


contract EuropaVault is Ownable {

    error VaultIsNotNew();
    error OnlyNewVault();
    error OnlyIoRent();


    /// Initial eth and local balances.
    uint256 immutable public initialEthBalance;
    uint256 immutable public initialLocBalance;

    /// Number of months.
    uint32 immutable public outAtStrike;

    address public ioRent;

    /// Actual/current eth and local balances.
    /// @notice the localBalance is of a compatible IERC20, most likely USD or MXN.
    uint256 public locBalance;
    uint256 public ethBalance;

    /// Strikes starts at 0, out is called at strike n ⚾️.
    /// Strike-out means that the vault owner is now the property owner.
    uint256 public strikes;

    /// @dev nuance implementation to make sure that 1
    function isNew() public returns (bool) {
        return ioRent != address(0);
    }

    constructor(
        uint256 _initialEthBalance,
        uint256 _initialLocBalance,
        uint32 _outAtStrike,
    ) {
        initialEthBalance =  _initialEthBalance;
        initialLocBalance =  _initialLocBalance;
        outAtStrike =  _outAtStrike;

    }

    modifier onlyNew() {
        if (!isNew()) { revert OnlyNewVault(); }
        _;
    }

    modifier onlyIoRent() {
        if (msg.sender != ioRent) { revert OnlyIoRent(); }
        _;
    }

    /// @notice onlyNew is making sure that the IoRent address is Zero.
    function initialDeposit(
        uint256 _amount,
        address _ioRent
    ) public payable onlyNew {
        require(msg.value >= initialEthBalance);
        require(_amount >= initialLocBalance);

        ethBalance = msg.value;
        locBalance = _amount;
        ioRent = _ioRent;

        IERC20 local = IERC20(localCurrency);
        local.safeTransferFrom(_ioRent, address(this), _amount);

        // emit VaultInitialized
    }

}