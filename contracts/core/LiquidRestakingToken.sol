// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ILiquidRestakingToken} from "../interfaces/ILiquidRestakingToken.sol";

/**
 * @author Georgi Chonkov
 * @notice Liquid Restaking Token (LRT)
 */
contract LiquidRestakingToken is ILiquidRestakingToken, Ownable, ERC20 {
    // name: Liquid Restaked Ether, symbol: rstETH

    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) ERC20(name_, symbol_) {}

    /**
     * @notice Only owner (Liquid Restaking Manager) can mint tokens
     */
    function mint(address account, uint256 value) external onlyOwner {
        _mint(account, value);
    }

    /**
     * @notice Only owner (Liquid Restaking Manager) can burn tokens
     */
    function burn(address account, uint256 value) external onlyOwner {
        _burn(account, value);
    }
}
