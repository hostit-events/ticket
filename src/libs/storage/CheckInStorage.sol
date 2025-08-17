// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.30;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// keccak256(abi.encode(uint256(keccak256("host.it.ticket.checkin.storage")) - 1)) & ~bytes32(uint256(0xff))
bytes32 constant CHECKIN_STORAGE_POSITION = 0xe193d680ae43ded63724eb4ee4d68fd7efbded9778d44414c0bab0177a079700;

struct CheckInStorage {
    mapping(uint56 => EnumerableSet.AddressSet) checkedIn;
    mapping(uint56 => mapping(uint8 => EnumerableSet.AddressSet)) checkedInByDay;
}
