const TestNFT = artifacts.require("TestNFT");

module.exports = async function (deployer) {
    try {
        await deployer.deploy(TestNFT, "Noodles", "NOODS");

        const testNFT = await TestNFT.deployed();

        console.log('deploy test success: ', testNFT.address);
    } catch (e) {
        console.log('e: ', e);
    }
};
