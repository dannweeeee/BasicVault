//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC20Mock } from "../lib/yield-utils-v2/src/mocks/ERC20Mock.sol";

contract FunToken is ERC20Mock {
    constructor() ERC20Mock("FunToken", "FUN") {
   
    }
}