// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Diamond} from "@diamond/Diamond.sol";
import {DiamondArgs, FacetCut} from "@diamond-storage/DiamondStorage.sol";

/*
          _____                   _______                   _____                _____                            _____                _____          
         /\    \                 /::\    \                 /\    \              /\    \                          /\    \              /\    \         
        /::\____\               /::::\    \               /::\    \            /::\    \                        /::\    \            /::\    \        
       /:::/    /              /::::::\    \             /::::\    \           \:::\    \                       \:::\    \           \:::\    \       
      /:::/    /              /::::::::\    \           /::::::\    \           \:::\    \                       \:::\    \           \:::\    \      
     /:::/    /              /:::/~~\:::\    \         /:::/\:::\    \           \:::\    \                       \:::\    \           \:::\    \     
    /:::/____/              /:::/    \:::\    \       /:::/__\:::\    \           \:::\    \                       \:::\    \           \:::\    \    
   /::::\    \             /:::/    / \:::\    \      \:::\   \:::\    \          /::::\    \                      /::::\    \          /::::\    \   
  /::::::\    \   _____   /:::/____/   \:::\____\   ___\:::\   \:::\    \        /::::::\    \            ____    /::::::\    \        /::::::\    \  
 /:::/\:::\    \ /\    \ |:::|    |     |:::|    | /\   \:::\   \:::\    \      /:::/\:::\    \          /\   \  /:::/\:::\    \      /:::/\:::\    \ 
/:::/  \:::\    /::\____\|:::|____|     |:::|    |/::\   \:::\   \:::\____\    /:::/  \:::\____\        /::\   \/:::/  \:::\____\    /:::/  \:::\____\
\::/    \:::\  /:::/    / \:::\    \   /:::/    / \:::\   \:::\   \::/    /   /:::/    \::/    /        \:::\  /:::/    \::/    /   /:::/    \::/    /
 \/____/ \:::\/:::/    /   \:::\    \ /:::/    /   \:::\   \:::\   \/____/   /:::/    / \/____/          \:::\/:::/    / \/____/   /:::/    / \/____/ 
          \::::::/    /     \:::\    /:::/    /     \:::\   \:::\    \      /:::/    /                    \::::::/    /           /:::/    /          
           \::::/    /       \:::\__/:::/    /       \:::\   \:::\____\    /:::/    /                      \::::/____/           /:::/    /           
           /:::/    /         \::::::::/    /         \:::\  /:::/    /    \::/    /                        \:::\    \           \::/    /            
          /:::/    /           \::::::/    /           \:::\/:::/    /      \/____/                          \:::\    \           \/____/             
         /:::/    /             \::::/    /             \::::::/    /                                         \:::\    \                              
        /:::/    /               \::/____/               \::::/    /                                           \:::\____\                             
        \::/    /                 ~~                      \::/    /                                             \::/    /                             
         \/____/                                           \/____/                                               \/____/                              
*/
/// @notice Implements EIP-2535 Diamond proxy pattern, allowing dynamic addition, replacement, and removal of facets
/// @author HostIt Protocol
contract HostIt is Diamond {
    /// @notice Initializes the Diamond proxy with the provided facets and initialization parameters
    /// @param _diamondCut Array of FacetCut structs defining facet addresses, corresponding function selectors, and actions (Add, Replace, Remove)
    /// @param _args Struct containing the initial owner address, optional init contract address, and init calldata
    constructor(FacetCut[] memory _diamondCut, DiamondArgs memory _args) payable Diamond(_diamondCut, _args) {}
}
