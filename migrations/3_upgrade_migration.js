const Hasai = artifacts.require("Hasai");
const { prepareUpgrade, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

const proxy = '';

module.exports = async function (deployer) {
    try {
        await prepareUpgrade(proxy, Hasai, { deployer });

        await upgradeProxy(proxy, Hasai, { deployer, initializer: 'initialize' });

        console.table({ Hasai: Hasai.address });
    } catch (e) {
        console.log('e: ', e.message);
    }
};
