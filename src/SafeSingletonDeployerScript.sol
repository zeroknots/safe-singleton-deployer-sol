// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VmSafe} from "forge-std/Vm.sol";

/// @notice Library for deploying contracts using Safe's Singleton Factory
///         https://github.com/safe-global/safe-singleton-factory
/// @dev This version is for use in Forge scripts (includes VM cheat codes)
library SafeSingletonDeployerScript {
    error DeployFailed();

    address constant SAFE_SINGLETON_FACTORY = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;
    VmSafe private constant VM = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function computeAddress(bytes memory creationCode, bytes32 salt) public pure returns (address) {
        return computeAddress(creationCode, "", salt);
    }

    function computeAddress(bytes memory creationCode, bytes memory args, bytes32 salt) public pure returns (address) {
        return VM.computeCreate2Address({
            salt: salt,
            initCodeHash: _hashInitCode(creationCode, args),
            deployer: SAFE_SINGLETON_FACTORY
        });
    }

    function broadcastDeploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        VM.broadcast();
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(bytes memory creationCode, bytes32 salt) internal returns (address) {
        VM.broadcast();
        return _deploy(creationCode, "", salt);
    }


    function broadcastDeploy(uint256 deployerKey, bytes memory creationCode, bytes memory args, bytes32 salt)
        internal
        returns (address)
    {
        VM.broadcast(deployerKey);
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(uint256 deployerKey, bytes memory creationCode, bytes32 salt)
        internal
        returns (address)
    {
        VM.broadcast(deployerKey);
        return _deploy(creationCode, "", salt);
    }

    function safeBroadcastDeploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        address predicted = computeAddress(creationCode, args, salt);
        if (predicted.code.length > 0) {
            return predicted;
        }
        VM.broadcast();
        return _deploy(creationCode, args, salt);
    }

    function safeBroadcastDeploy(bytes memory creationCode, bytes32 salt) internal returns (address) {
        address predicted = computeAddress(creationCode, salt);
        if (predicted.code.length > 0) {
            return predicted;
        }
        VM.broadcast();
        return _deploy(creationCode, "", salt);
    }

    function safeBroadcastDeploy(uint256 deployerKey, bytes memory creationCode, bytes memory args, bytes32 salt)
        internal
        returns (address)
    {
        address predicted = computeAddress(creationCode, args, salt);
        if (predicted.code.length > 0) {
            return predicted;
        }
        VM.broadcast(deployerKey);
        return _deploy(creationCode, args, salt);
    }

    function safeBroadcastDeploy(uint256 deployerKey, bytes memory creationCode, bytes32 salt)
        internal
        returns (address)
    {
        address predicted = computeAddress(creationCode, salt);
        if (predicted.code.length > 0) {
            return predicted;
        }
        VM.broadcast(deployerKey);
        return _deploy(creationCode, "", salt);
    }

    /// @dev Allows calling without Forge broadcast
    function deploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        return _deploy(creationCode, args, salt);
    }

    /// @dev Allows calling without Forge broadcast
    function deploy(bytes memory creationCode, bytes32 salt) internal returns (address) {
        return _deploy(creationCode, "", salt);
    }

    function _deploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        bytes memory callData = abi.encodePacked(salt, creationCode, args);

        (bool success, bytes memory result) = SAFE_SINGLETON_FACTORY.call(callData);

        if (!success) {
            // contract does not pass on revert reason
            // https://github.com/Arachnid/deterministic-deployment-proxy/blob/master/source/deterministic-deployment-proxy.yul#L13
            revert DeployFailed();
        }

        return address(bytes20(result));
    }

    function _hashInitCode(bytes memory creationCode, bytes memory args) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(creationCode, args));
    }
}
