const ACYToken = artifacts.require("ACYToken");
const SACYToken = artifacts.require("sACYToken");
const ACYStaking = artifacts.require("ACYStaking");
const IterableMap = artifacts.require("IterableMapping")

module.exports = (deployer, network, [owner]) => {
    deployer.then(async () => {
        const iterableMap = await IterableMap.new()

        await ACYStaking.detectNetwork();
        await ACYStaking.link("IterableMapping", iterableMap.address);

        await deployer.deploy(ACYStaking);
        const acyStaking = await ACYStaking.deployed();

        await deployer.deploy(ACYToken, acyStaking.address);
        const acyToken = await ACYToken.deployed();
        await acyToken.mint(owner, "100000000000000000000");
        await acyToken.mint("0xCACdA46bD4dc2125AcD4c9254d440dADB022C001", "100000000000000000000");

        await deployer.deploy(SACYToken, acyStaking.address);
        const sacyToken = await SACYToken.deployed();

        await acyStaking.initialze(acyToken.address, sacyToken.address, "0xCACdA46bD4dc2125AcD4c9254d440dADB022C001", 10);

        const fs = require('fs');
        let config = `
        export const acyTokenAddress = "${acyToken.address}"
        export const sacyTokenAddress = ${sacyToken.address}
        export const acyStakingAddress = "${acyStaking.address}"
    `.replace(/^(\s+)(?=export)/gm, ``);
        let data = JSON.stringify(config);

        fs.writeFileSync('./config.js', JSON.parse(data))

    })
}