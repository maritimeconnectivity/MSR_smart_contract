const MsrContract = artifacts.require("MsrContract");

module.exports = function(deployer) {
    deployer.deploy(MsrContract);
};