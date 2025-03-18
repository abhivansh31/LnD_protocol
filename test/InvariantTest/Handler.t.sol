// //SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import {Test} from "forge-std/Test.sol";
// import {LendingPool} from "../../src/LendingPool.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {DeployLendingPool} from "../../script/DeployLendingPool.s.sol";
// import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

// contract Handler is Test {
//     LendingPool pool;
//     IERC20 token;
//     IERC20 weth;
//     uint256 funds = 10 * 10 ** 18;

//     constructor(LendingPool _pool, address _token, address _weth) {
//         pool = _pool;
//         token = IERC20(_token);
//         weth = IERC20(_weth);
//     }

//     function addLiquidity(uint256 amount) public payable{
//         amount = bound(amount, 0, funds/2);
//         IERC20(weth).approve(address(pool), amount);
//         pool.addLiquidity(amount);
//     }

//     function removeLiquidity() public {
//         pool.removeLiquidity();
//     }
// }