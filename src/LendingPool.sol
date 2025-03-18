//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title A lending and borrowing protocol
/// @author Abhivansh Saini
/// @notice This is a simple implementation of a lending and borrowing protocol. In this contract, there are two tokens, one is used as a collateral token and other as the borrowed token by the users. There is an overcollaterization of 200% in the protocol which safeguards the protocl against bad debt. The borrower are charged 0.1% interest per day and the lenders are given 0.03% interest per day. The protocol also allows liquidation of the borrowers if their health factor goes below 200%. The person who liquidates gets 1% as the liquidation bonus. The liquidity providers who can add liquidity only with the borrowed token are minted with ERC20 tokens to maintain the record of relative liquidity added.

contract LendingPool is ReentrancyGuard, ERC20 {
    IERC20 token;
    IERC20 weth;
    address priceFeedToken;
    address priceFeedEthereum;
    uint256 totalLiquidityAdded;

    /// @dev The BORROWER_INTEREST_RATE and the LENDER_INTEREST_RATE are the interest rates charged to the borrowers and the interest rates given to the lenders respectively.

    uint256 constant BORROWER_INTEREST_RATE = 10;
    uint256 constant LENDER_INTEREST_RATE = 3;

    /// @dev The LIQUIDATION_THRESHOLD is the percentage of the collateral value that the borrower can borrow and the LIQUIDATION_BONUS is the bonus that the liquidator gets on liquidating the borrower.

    uint256 constant LIQUIDATION_THRESHOLD = 50;
    uint256 constant LIQUIDATION_BONUS = 1;

    error Pool_AmountIsZero();
    error Pool_BorrowAmountMoreThanMaxBorrowableAmount();
    error Pool_HealthFactorIsOkay();
    error Pool_TransferFailed();

    event Pool_CollateralDepositedAndTokenBorrowed(
        address indexed user,
        uint256 depositAmount,
        uint256 borrowAmount
    );
    event Pool_LoanRepayed(
        address indexed user,
        uint256 amountGot,
        uint256 repayAmount
    );
    event Pool_Liquidated(
        address indexed userWhoDefaulted,
        address indexed liquidator,
        uint256 amountLiquidated
    );
    event Pool_LiquidityRemoved(
        address indexed liquidityProvider,
        uint256 amount
    );
    event Pool_LiquidityAdded(
        address indexed liquidityProvider,
        uint256 amount
    );

    constructor(
        address _token,
        address _weth,
        address _priceFeedToken,
        address _priceFeedEthereum
    ) ERC20("LP", "LP") {
        token = IERC20(_token);
        weth = IERC20(_weth);
        priceFeedToken = _priceFeedToken;
        priceFeedEthereum = _priceFeedEthereum;
    }

    struct User {
        uint256 tokenAmountBorrowed;
        uint256 amountCollateralDeposited;
        uint256 timeAtWhichHeDepositedCollateral;
    }

    /// @dev The userToUserDetails mapping stores the struct variables to the user addresses. The liquidityProviderToTimeAtWhichHeAddedLiquidity mapping stores the time at which the liquidity provider added the liquidity which helps in calculating the interest.

    mapping(address => User) public userToUserDetails;
    mapping(address user => uint256 time) liquidityProviderToTimeAtWhichHeAddedLiquidity;

    //////////////////////////////////////////////
    ////// FUNCTION FOR LIQUIDITY PROVIDERS //////
    //////////////////////////////////////////////

    /// @dev This function helps the liquidity provider to add the liquidity to the pool.
    /// @param amount The amount of token that the liquidity provider wants to add to the pool.

    function addLiquidity(uint256 amount) public nonReentrant {
        if (amount == 0) {
            revert Pool_AmountIsZero();
        }
        bool success = IERC20(address(token)).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) {
            revert Pool_TransferFailed();
        }
        liquidityProviderToTimeAtWhichHeAddedLiquidity[msg.sender] = block
            .timestamp;
        totalLiquidityAdded += amount;
        _mint(msg.sender, amount);
        emit Pool_LiquidityAdded(msg.sender, amount);
    }

    /// @dev This function helps the liquidity provider to remove the liquidity from the pool.

    function removeLiquidity() public nonReentrant {
        uint256 amount = (totalLiquidityAdded * balanceOf(msg.sender)) /
            totalSupply();
        uint256 timeElapsed = block.timestamp -
            liquidityProviderToTimeAtWhichHeAddedLiquidity[msg.sender];
        uint256 daysElapsed = timeElapsed / 1 days;
        uint256 interestAmount = (amount * daysElapsed * LENDER_INTEREST_RATE) /
            (10000 * 365 days);
        bool success = IERC20(address(token)).transfer(
            msg.sender,
            amount + interestAmount
        );
        if (!success) {
            revert Pool_TransferFailed();
        }
        _burn(msg.sender, balanceOf(msg.sender));
        totalLiquidityAdded -= amount;
        liquidityProviderToTimeAtWhichHeAddedLiquidity[msg.sender] = 0;
        emit Pool_LiquidityRemoved(msg.sender, amount + interestAmount);
    }

    ////////////////////////////////
    ////// FUNCTION FOR USERS //////
    ////////////////////////////////

    /// @dev This function helps the liquidator to liquidate the borrower if his health factor goes below 200%.

    function liquidate(address userWhoDefaulted, address liquidator) public {
        if (checkIfHealthFactorIsOkay(userWhoDefaulted)) {
            revert Pool_HealthFactorIsOkay();
        }
        uint256 tokenAmount = userToUserDetails[userWhoDefaulted]
            .tokenAmountBorrowed;
        uint256 collateralAmount = userToUserDetails[userWhoDefaulted]
            .amountCollateralDeposited;
        uint256 liquidationAmount = (collateralAmount * LIQUIDATION_BONUS) /
            100;
        bool successToken = IERC20(address(token)).transferFrom(
            liquidator,
            address(this),
            tokenAmount
        );
        if (!successToken) {
            revert Pool_TransferFailed();
        }
        bool successWeth = IERC20(address(weth)).transfer(
            liquidator,
            liquidationAmount + collateralAmount
        );
        if (!successWeth) {
            revert Pool_TransferFailed();
        }
        userToUserDetails[userWhoDefaulted].amountCollateralDeposited = 0;
        userToUserDetails[userWhoDefaulted].tokenAmountBorrowed = 0;
        userToUserDetails[userWhoDefaulted]
            .timeAtWhichHeDepositedCollateral = 0;
        emit Pool_Liquidated(
            userWhoDefaulted,
            liquidator,
            liquidationAmount + collateralAmount
        );
    }

    /// @dev This function helps the user to deposit the collateral and borrow the token.
    /// @param depositAmount The amount of the collateral that the user wants to deposit.
    /// @param borrowAmount The amount of token that the user wants to borrow.

    function depositCollateralAndBorrowToken(
        uint256 depositAmount,
        uint256 borrowAmount
    ) public nonReentrant {
        uint256 depositAmountValue = calculateUsdValue(
            depositAmount,
            priceFeedEthereum
        );
        uint256 maxBorrowedToken = calculateMaximumBorrowingAmount(
            depositAmountValue
        );
        require(
            maxBorrowedToken >= borrowAmount,
            Pool_BorrowAmountMoreThanMaxBorrowableAmount()
        );
        userToUserDetails[msg.sender].tokenAmountBorrowed += borrowAmount;
        userToUserDetails[msg.sender]
            .amountCollateralDeposited += depositAmount;
        userToUserDetails[msg.sender].timeAtWhichHeDepositedCollateral = block
            .timestamp;
        bool successWeth = IERC20(address(weth)).transferFrom(
            msg.sender,
            address(this),
            depositAmount
        );
        if (!successWeth) {
            revert Pool_TransferFailed();
        }
        bool successToken = IERC20(address(token)).transfer(
            msg.sender,
            borrowAmount
        );
        if (!successToken) {
            revert Pool_TransferFailed();
        }
        emit Pool_CollateralDepositedAndTokenBorrowed(
            msg.sender,
            depositAmount,
            borrowAmount
        );
    }

    /// @dev This function helps the user to repay the loan and withdraw the collateral. The interest is deducted from the weth that he has deposited while borrowing the token.

    function repayLoan() public nonReentrant {
        uint256 principalAmount = userToUserDetails[msg.sender]
            .amountCollateralDeposited;
        uint256 interestAmount = calculateInterest();
        uint256 totalAmount = principalAmount - interestAmount;
        uint256 tokenAmount = userToUserDetails[msg.sender].tokenAmountBorrowed;
        bool successToken = IERC20(address(token)).transferFrom(
            msg.sender,
            address(this),
            tokenAmount
        );
        if (!successToken) {
            revert Pool_TransferFailed();
        }
        bool successWeth = IERC20(address(weth)).transfer(
            msg.sender,
            totalAmount
        );
        if (!successWeth) {
            revert Pool_TransferFailed();
        }
        userToUserDetails[msg.sender].amountCollateralDeposited = 0;
        userToUserDetails[msg.sender].tokenAmountBorrowed = 0;
        userToUserDetails[msg.sender].timeAtWhichHeDepositedCollateral = 0;
        emit Pool_LoanRepayed(msg.sender, totalAmount, tokenAmount);
    }

    /// @dev This function helps in calculating the interest that the user has to pay.
    /// @return The interest amount that the user has to pay.

    function calculateInterest() internal view returns (uint256) {
        uint256 value = calculateUsdValue(
            userToUserDetails[msg.sender].amountCollateralDeposited,
            priceFeedEthereum
        );
        if (value == 0) {
            return 0;
        }
        uint256 timeElapsed = block.timestamp -
            userToUserDetails[msg.sender].timeAtWhichHeDepositedCollateral;
        uint256 daysElapsed = timeElapsed / 1 days;
        uint256 interestAmount = (value *
            daysElapsed *
            BORROWER_INTEREST_RATE) / (10000 * 365 days);
        return interestAmount;
    }

    /// @dev This functions helps in calculating the value of the collateral deposited by the user in USD by using the Chainlink pricefeed.
    /// @param amount The amount of collateral or token whose value is to be calculated.
    /// @param pricefeed The address of the pricefeed of the token or the collateral (weth).
    /// @return The value of the collateral in USD.

    function calculateUsdValue(
        uint256 amount,
        address pricefeed
    ) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(pricefeed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price) * 1e10 * amount) / 1e18;
    }

    /// @dev This function helps in calculating the maximum amount of token that the user can borrow.
    /// @param collateralValue The value of the collateral deposited by the user.
    /// @return The maximum amount of token that the user can borrow.

    function calculateMaximumBorrowingAmount(
        uint256 collateralValue
    ) internal view returns (uint256) {
        uint256 borrowedTokenValue = (collateralValue * LIQUIDATION_THRESHOLD) /
            100;
        uint256 tokenPrice = calculateUsdValue(1, priceFeedToken);
        uint256 maxTokenAmount = borrowedTokenValue / tokenPrice;
        if (maxTokenAmount == 0) {
            revert Pool_AmountIsZero();
        }
        return maxTokenAmount;
    }

    /// @dev This function helps in checking the health factor of the user for liquidation.
    /// @param user The address of the user whose health factor is to be checked.
    /// @return A boolean value indicating whether the health factor is okay or not.

    function checkIfHealthFactorIsOkay(
        address user
    ) public view returns (bool) {
        uint256 collateralValue = calculateUsdValue(
            userToUserDetails[user].amountCollateralDeposited,
            priceFeedEthereum
        );
        uint256 borrowedTokenValue = calculateUsdValue(
            userToUserDetails[user].tokenAmountBorrowed,
            priceFeedToken
        );
        uint256 healthFactor = (collateralValue * 100) / borrowedTokenValue;
        if (healthFactor >= 200) {
            return true;
        }
        return false;
    }

    //////////////////////////////
    ////// GETTER FUNCTIONS //////
    //////////////////////////////

    /// @dev This function helps in getting the borrowed amount of the user.

    function getBorrowedAmount() public view returns (uint256) {
        return userToUserDetails[msg.sender].tokenAmountBorrowed;
    }

    /// @dev This function helps in getting the deposited collateral amount of the user.

    function getDepositedCollateral() public view returns (uint256) {
        return userToUserDetails[msg.sender].amountCollateralDeposited;
    }

    /// @dev This function gives the total liquidity added in the pool by the liquidity providers.

    function getTotalLiquidityAdded() public view returns(uint256) {
        return totalLiquidityAdded;
    }

    /// @dev This function gives the LP tokens to the liquidity providers.

    function getLPTokens(address user) public view returns(uint256) {
        return balanceOf(user);
    }
}
