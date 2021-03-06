const MsrContract = artifacts.require("MsrContract");

// use this to preload the contract with dummy data
module.exports = async function(deployer, network, accounts) {
    await deployer.deploy(MsrContract);
    const instance = await MsrContract.deployed();
    const MSR_ADMIN_ROLE = await instance.MSR_ADMIN_ROLE.call();
    const initialStatus = MsrContract.InstanceStatus.Provisional;
    await instance.grantRole(MSR_ADMIN_ROLE, accounts[0], {from: accounts[0]});
    await instance.addMsr('MSR 1', 'https://example.com', accounts[0], {from: accounts[0]});
    const service = 
        {
            name: 'instance 1', 
            mrn: 'urn:mrn:mcp:service:mcc:core:instance:example', 
            version: '0.1', 
            keywords: '', 
            coverageArea: 'POLYGON((10.689 -25.092, 34.595 -20.170, 38.814 -35.639, 13.502 -39.155, 10.689 -25.092))', 
            status: initialStatus,
            implementsDesignMRN: 'urn:mrn:mcp:service:mcc:core:design:example', 
            implementsDesignVersion: '0.1',
            msrName: '',
            msrUrl: ''
        };
    await instance.registerServiceInstance(service, ['kw1', 'kw2'], {from: accounts[0]});
};
// use this to NOT preload the contract with dummy data
// module.exports = function(deployer) {
//     deployer.deploy(MsrContract);
// }