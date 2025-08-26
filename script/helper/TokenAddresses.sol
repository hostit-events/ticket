// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {FeeType} from "@ticket-storage/MarketplaceStorage.sol";

library TokenAddresses {
    //*//////////////////////////////////////////////////////////////////////////
    //                             MAINNET ADDRESSES
    //////////////////////////////////////////////////////////////////////////*//

    function _getEthereumFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](5);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.USDT);
        feeType_[2] = uint8(FeeType.GHO);
        feeType_[3] = uint8(FeeType.LINK);
        feeType_[4] = uint8(FeeType.WETH);
    }

    function _getEtheremAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](5);
        addresses_[0] = ETH_USDC;
        addresses_[1] = ETH_USDT;
        addresses_[2] = ETH_GHO;
        addresses_[3] = ETH_LINK;
        addresses_[4] = ETH_WETH;
    }

    function _getBaseFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](6);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.USDT);
        feeType_[2] = uint8(FeeType.GHO);
        feeType_[3] = uint8(FeeType.LINK);
        feeType_[4] = uint8(FeeType.WETH);
        feeType_[5] = uint8(FeeType.EURC);
    }

    function _getBaseAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](6);
        addresses_[0] = BASE_USDC;
        addresses_[1] = BASE_USDT;
        addresses_[2] = BASE_GHO;
        addresses_[3] = BASE_LINK;
        addresses_[4] = BASE_WETH;
        addresses_[5] = BASE_EURC;
    }

    function _getAvalancheFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](4);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.GHO);
        feeType_[2] = uint8(FeeType.LINK);
        feeType_[3] = uint8(FeeType.WETH);
    }

    function _getAvalancheAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](4);
        addresses_[0] = AVALANCHE_USDC;
        addresses_[1] = AVALANCHE_GHO;
        addresses_[2] = AVALANCHE_LINK;
        addresses_[3] = AVALANCHE_WAVAX;
    }

    function _getArbitrumOneFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](4);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.GHO);
        feeType_[2] = uint8(FeeType.LINK);
        feeType_[3] = uint8(FeeType.WETH);
    }

    function _getArbitrumOneAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](4);
        addresses_[0] = ARBITRUM_ONE_USDC;
        addresses_[1] = ARBITRUM_ONE_GHO;
        addresses_[2] = ARBITRUM_ONE_LINK;
        addresses_[3] = ARBITRUM_ONE_WETH;
    }

    function _getLiskFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](6);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.USDT);
        feeType_[2] = uint8(FeeType.EURC);
        feeType_[3] = uint8(FeeType.LSK);
        feeType_[4] = uint8(FeeType.LINK);
        feeType_[5] = uint8(FeeType.USDT0);
    }

    function _getLiskAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](6);
        addresses_[0] = LISK_USDC;
        addresses_[1] = LISK_USDT;
        addresses_[2] = LISK_EURC;
        addresses_[3] = LISK_LSK;
        addresses_[4] = LISK_LINK;
        addresses_[5] = LISK_USDT0;
    }

    //*//////////////////////////////////////////////////////////////////////////
    //                             TESTNET ADDRESSES
    //////////////////////////////////////////////////////////////////////////*//

    function _getEthereumSepoliaFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](3);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.LINK);
        feeType_[2] = uint8(FeeType.WETH);
    }

    function _getEthereumSepoliaAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](3);
        addresses_[0] = ETH_SEPOLIA_USDC;
        addresses_[1] = ETH_SEPOLIA_LINK;
        addresses_[2] = ETH_SEPOLIA_WETH;
    }

    function _getBaseSepoliaFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](5);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.USDT);
        feeType_[2] = uint8(FeeType.LINK);
        feeType_[3] = uint8(FeeType.WETH);
        feeType_[4] = uint8(FeeType.EURC);
    }

    function _getBaseSepoliaAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](5);
        addresses_[0] = BASE_SEPOLIA_USDC;
        addresses_[1] = BASE_SEPOLIA_USDT;
        addresses_[2] = BASE_SEPOLIA_LINK;
        addresses_[3] = BASE_SEPOLIA_WETH;
        addresses_[4] = BASE_SEPOLIA_EURC;
    }

    function _getAvalancheFujiFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](3);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.LINK);
        feeType_[2] = uint8(FeeType.WETH);
    }

    function _getAvalancheFujiAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](3);
        addresses_[0] = AVALANCHE_FUJI_USDC;
        addresses_[1] = AVALANCHE_FUJI_LINK;
        addresses_[2] = AVALANCHE_FUJI_WAVAX;
    }

    function _getArbitrumSepoliaFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](3);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.LINK);
        feeType_[2] = uint8(FeeType.WETH);
    }

    function _getArbitrumSepoliaAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](3);
        addresses_[0] = ARBITRUM_SEPOLIA_USDC;
        addresses_[1] = ARBITRUM_SEPOLIA_LINK;
        addresses_[2] = ARBITRUM_SEPOLIA_WETH;
    }

    function _getLiskSepoliaFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](4);
        feeType_[0] = uint8(FeeType.USDC);
        feeType_[1] = uint8(FeeType.LINK);
        feeType_[2] = uint8(FeeType.WETH);
        feeType_[3] = uint8(FeeType.LSK);
    }

    function _getLiskSepoliaAddresses() internal pure returns (address[] memory addresses_) {
        addresses_ = new address[](4);
        addresses_[0] = LISK_SEPOLIA_USDC;
        addresses_[1] = LISK_SEPOLIA_LINK;
        addresses_[2] = LISK_SEPOLIA_WETH;
        addresses_[3] = LISK_SEPOLIA_LSK;
    }

    function _getMockFeeTypes() internal pure returns (uint8[] memory feeType_) {
        feeType_ = new uint8[](8);
        feeType_[0] = uint8(FeeType.WETH);
        feeType_[1] = uint8(FeeType.USDT);
        feeType_[2] = uint8(FeeType.USDC);
        feeType_[3] = uint8(FeeType.EURC);
        feeType_[4] = uint8(FeeType.USDT0);
        feeType_[5] = uint8(FeeType.GHO);
        feeType_[6] = uint8(FeeType.LINK);
        feeType_[7] = uint8(FeeType.LSK);
    }

    function _getMockAddresses() internal returns (address[] memory addresses_) {
        addresses_ = new address[](8);
        addresses_[0] = address(new ERC20Mock());
        addresses_[1] = address(new ERC20Mock());
        addresses_[2] = address(new ERC20Mock());
        addresses_[3] = address(new ERC20Mock());
        addresses_[4] = address(new ERC20Mock());
        addresses_[5] = address(new ERC20Mock());
        addresses_[6] = address(new ERC20Mock());
        addresses_[7] = address(new ERC20Mock());
    }
}

//*//////////////////////////////////////////////////////////////////////////
//                             ETHEREUM ADDRESSES
//////////////////////////////////////////////////////////////////////////*//

address constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
address constant ETH_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
address constant ETH_GHO = 0x40D16FC0246aD3160Ccc09B8D0D3A2cD28aE6C2f;
address constant ETH_LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
address constant ETH_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

//*//////////////////////////////////////////////////////////////////////////
//                         ETHEREUM SEPOLIA ADDRESSES
//////////////////////////////////////////////////////////////////////////*//

address constant ETH_SEPOLIA_USDC = 0xf661043d9Bc1ef2169Ef90ad3b2285Cf8Bfc0AE2;
address constant ETH_SEPOLIA_LINK = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
address constant ETH_SEPOLIA_WETH = 0x097D90c9d3E0B50Ca60e1ae45F6A81010f9FB534;

//*//////////////////////////////////////////////////////////////////////////
//                               BASE ADDRESSES
//////////////////////////////////////////////////////////////////////////*//

address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
address constant BASE_USDT = 0x1217BfE6c773EEC6cc4A38b5Dc45B92292B6E189;
address constant BASE_GHO = 0x6Bb7a212910682DCFdbd5BCBb3e28FB4E8da10Ee;
address constant BASE_LINK = 0x88Fb150BDc53A65fe94Dea0c9BA0a6dAf8C6e196;
address constant BASE_WETH = 0x4200000000000000000000000000000000000006;
address constant BASE_EURC = 0x60a3E35Cc302bFA44Cb288Bc5a4F316Fdb1adb42;

//*//////////////////////////////////////////////////////////////////////////
//                           BASE SEPOLIA ADDRESSES
//////////////////////////////////////////////////////////////////////////*//

address constant BASE_SEPOLIA_USDC = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
address constant BASE_SEPOLIA_USDT = 0x7169D38820dfd117C3FA1f22a697dBA58d90BA06;
address constant BASE_SEPOLIA_LINK = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
address constant BASE_SEPOLIA_WETH = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;
address constant BASE_SEPOLIA_EURC = 0x808456652fdb597867f38412077A9182bf77359F;

//*//////////////////////////////////////////////////////////////////////////
//                               LISK ADDRESSES
//////////////////////////////////////////////////////////////////////////*//

address constant LISK_USDC = 0xF242275d3a6527d877f2c927a82D9b057609cc71;
address constant LISK_USDT = 0x05D032ac25d322df992303dCa074EE7392C117b9;
address constant LISK_EURC = 0xe12cEFaAD61e551691BFa5cDA36e5dE051778C65;
address constant LISK_LSK = 0x8a21CF9Ba08Ae709D64Cb25AfAA951183EC9FF6D;
address constant LISK_LINK = 0x71052BAe71C25C78E37fD12E5ff1101A71d9018F;
address constant LISK_USDT0 = 0x43F2376D5D03553aE72F4A8093bbe9de4336EB08;

//*//////////////////////////////////////////////////////////////////////////
//                           LISK SEPOLIA ADDRESSES
//////////////////////////////////////////////////////////////////////////*//

address constant LISK_SEPOLIA_USDC = 0x0E82fDDAd51cc3ac12b69761C45bBCB9A2Bf3C83;
address constant LISK_SEPOLIA_LINK = 0x6641415a61bCe80D97a715054d1334360Ab833Eb;
address constant LISK_SEPOLIA_WETH = 0x4200000000000000000000000000000000000006;
address constant LISK_SEPOLIA_LSK = 0x8a21CF9Ba08Ae709D64Cb25AfAA951183EC9FF6D;

//*//////////////////////////////////////////////////////////////////////////
//                            AVALANCHE ADDRESSES
//////////////////////////////////////////////////////////////////////////*//

address constant AVALANCHE_USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
address constant AVALANCHE_GHO = 0xfc421aD3C883Bf9E7C4f42dE845C4e4405799e73;
address constant AVALANCHE_LINK = 0x5947BB275c521040051D82396192181b413227A3;
address constant AVALANCHE_WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

//*//////////////////////////////////////////////////////////////////////////
//                          AVALANCHE FUJI ADDRESSES
//////////////////////////////////////////////////////////////////////////*///

address constant AVALANCHE_FUJI_USDC = 0x7bA2e5c37C4151d654Fcc4b41ffF3Fe693c23852;
address constant AVALANCHE_FUJI_LINK = 0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846;
address constant AVALANCHE_FUJI_WAVAX = 0xd00ae08403B9bbb9124bB305C09058E32C39A48c;

//*//////////////////////////////////////////////////////////////////////////
//                           ARBITRUM ONE ADDRESSES
//////////////////////////////////////////////////////////////////////////*//

address constant ARBITRUM_ONE_USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
address constant ARBITRUM_ONE_GHO = 0x7dfF72693f6A4149b17e7C6314655f6A9F7c8B33;
address constant ARBITRUM_ONE_LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;
address constant ARBITRUM_ONE_WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

//*//////////////////////////////////////////////////////////////////////////
//                         ARBITRUM SEPOLIA ADDRESSES
//////////////////////////////////////////////////////////////////////////*//

address constant ARBITRUM_SEPOLIA_USDC = 0x5Df6eD08EEC2fD5e41914d291c0cf48Cd3564421;
address constant ARBITRUM_SEPOLIA_LINK = 0xb1D4538B4571d411F07960EF2838Ce337FE1E80E;
address constant ARBITRUM_SEPOLIA_WETH = 0xE591bf0A0CF924A0674d7792db046B23CEbF5f34;
