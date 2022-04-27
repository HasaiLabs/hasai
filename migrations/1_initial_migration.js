const Hasai = artifacts.require("Hasai");
const { ethers } = require('ethers');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer) {
    try {
        await deployProxy(Hasai, [
            '[WETH Address]',
            '[Oracle Address]'
        ],
        {
            deployer,
            initializer: 'initialize'
        });

        console.table({ address: Hasai.address });
    } catch (e) {
        console.log('e: ', e.message);
    }
};
