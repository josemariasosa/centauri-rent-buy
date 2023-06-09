pragma solidity ^0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IEuropaVault.sol";
import "./interfaces/IIoRent.sol";
import "./EuropaVault.sol";

/// Rent contract between Property Owner (PO) 👷‍♀️ and Locataire (LO) 🧢.
/// The locataire owns the vault with the Security Deposit (SD), but the ownership
/// could be removed if the locataire receive a pre-stablished amount of strikes.

/// If the Locataire is striked out, the remaining Security Deposit goes to the PO.
/// Every strike, release a fixed eth amount from the vault balance to the PO,
/// that can be pulled out any time, or withdraw them in local currency.

contract IoRent is IIoRent {
    using SafeERC20 for IERC20;

    /// @notice v0.1.0 can handle 1 year contract.
    uint32 public constant MAX_CONTRACT_DURATION = 12;

    error InvalidNewVault();
    error NotTheOwner();
    error NotTheLocataire();
    error AlreadyAccepted();

    address immutable public propertyOwner;
    address immutable public locataire;

    address public acceptedBy;

    EuropaVault immutable public europaVault;

    /// The rent contract will manage 2 currencies:
    /// ether and the local currency USD or MXN.
    IERC20 immutable public localCurrency;
    uint256 immutable public rentAmount;
    uint256 immutable public firstMonthsRent;
    uint32 immutable public durationInMonths;

    uint64 immutable public acceptUntilTimestamp;

    modifier onlyOwner() {
        _assertOnlyOwner();
        _;
    }

    modifier onlyLocataire() {
        _assertOnlyLocataire();
        _;
    }

    function _assertOnlyOwner() private {
        if msg.sender != propertyOwner { revert NotTheOwner(); }
    }

    function _assertOnlyLocataire() private {
        if msg.sender != locataire { revert NotTheLocataire(); }
    }

    function constructor(
        IERC20 _localCurrencyAddress,
        address _locataire,
        uint256 _rentAmount,
        uint256 _firstMonthsRent,
        uint32 _durationInMonths,
        uint64 _acceptUntilTimestamp,

        uint256 _initialEthBalance,
        uint256 _initialLocBalance,
        uint32 _outAtStrike;
    ) {
        propertyOwner = msg.sender;
        locataire = _locataire;

        europaVault = new EuropaVault(_initialEthBalance, _initialLocBalance, _outAtStrike);
        localCurrency = _localCurrencyAddress;

        rentAmount = _rentAmount;
        firstMonthsRent = _firstMonthsRent;
        durationInMonths = _durationInMonths;

        if (_acceptUntilTimestamp <= block.timestamp) { revert InvalidTimestamp(); }
        acceptUntilTimestamp = _acceptUntilTimestamp;
    }

    /// @notice The contract can only be accepted once.
    function acceptContract(uint256 _amount) public payable onlyLocataire {
        if (acceptedBy != address(0)) { revert AlreadyAccepted(); }
        require(block.timestamp <= _acceptUntilTimestamp);
        // IMPORTANT: the amount MUST cover the initial eth balance and the first rent.
        require(_amount >= (europaVault.initialEthBalance + firstMonthsRent));

        // The brave 🦁 trakes risks. Only the Locataire.
        acceptedBy = msg.sender;

        IERC20 local = IERC20(localCurrency);
        local.safeTransferFrom(msg.sender, address(this), _amount);
        local.safeIncreaseAllowance(address(europaVault), _amount);

        europaVault.initialDeposit(uint256 _amount, address(this));
    }

    /// TODO: This might be address(this), not sure ⁉️
    // function getVaultAddress() public view returns (address) {
    //     return address(europaVault);
    // }



    // uint public unlockTime;
    // address payable public owner;

    // event Withdrawal(uint amount, uint when);

    // constructor(uint _unlockTime) payable {
    //     require(
    //         block.timestamp < _unlockTime,
    //         "Unlock time should be in the future"
    //     );

    //     unlockTime = _unlockTime;
    //     owner = payable(msg.sender);
    // }

    // function withdraw() public {
    //     // Uncomment this line, and the import of "hardhat/console.sol", to print a log in your terminal
    //     // console.log("Unlock time is %o and block timestamp is %o", unlockTime, block.timestamp);

    //     require(block.timestamp >= unlockTime, "You can't withdraw yet");
    //     require(msg.sender == owner, "You aren't the owner");

    //     emit Withdrawal(address(this).balance, block.timestamp);

    //     owner.transfer(address(this).balance);
    // }
}
