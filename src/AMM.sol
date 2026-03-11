// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract AMM is ERC20 {
    address public tokenA;
    address public tokenB;
    uint public reserveA;
    uint public reserveB;

    event Swap(
        address indexed user,
        address tokenIn,
        uint amountIn,
        uint amountOut
    );

    constructor(address _tokenA, address _tokenB) ERC20("LP Token", "LP") {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function addLiquidity(uint amountA, uint amountB) public {
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        uint liquidity;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            liquidity = Math.min(
                (amountA * totalSupply()) / reserveA,
                (amountB * totalSupply()) / reserveB
            );
        }

        require(liquidity > 0, "insufficient liquidity");

        _mint(msg.sender, liquidity);

        reserveA += amountA;
        reserveB += amountB;
    }

    function removeLiquidity(uint liquidity) public {
        require(liquidity > 0, "insufficient liquidity");

        uint amountA = (reserveA * liquidity) / totalSupply();
        uint amountB = (reserveB * liquidity) / totalSupply();

        _burn(msg.sender, liquidity);

        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        reserveA -= amountA;
        reserveB -= amountB;
    }

    function swap(address tokenIn, uint amountIn) public {
        require(tokenIn == tokenA || tokenIn == tokenB, "invalid token");
        (uint reserveIn, uint reserveOut, address tokenOut) = tokenIn == tokenA
            ? (reserveA, reserveB, tokenB)
            : (reserveB, reserveA, tokenA);
        uint amountInWithFee = (amountIn * 997) / 1000;

        uint amountOut = (reserveOut * amountInWithFee) /
            (reserveIn + amountInWithFee);
        require(amountOut > 0, "insufficient output");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        if (tokenIn == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }
}
