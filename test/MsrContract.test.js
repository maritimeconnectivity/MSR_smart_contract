const { expect } = require('chai');
const { BN, expectEvent, expectRevert } =  require('@openzeppelin/test-helpers');

const MsrContract = artifacts.require("MsrContract");

contract('MsrContract', ([owner, other, msr1]) => {
    beforeEach(async () => {
        this.msrContract = await MsrContract.new({from: owner});
        await this.msrContract.grantRole(await this.msrContract.MSR_ADMIN_ROLE(), owner, {from: owner});
    });

    it('Gets the list of service instances', async() => {
        const array = await this.msrContract.getServiceInstances({from: other});
        expect(array.length == 0);
    });

    it('creates a service instance to msr1', async() => {
        let array = await this.msrContract.getServiceInstances({from: other});
        expect(array.length == 0);

        await this.msrContract.addMsr("MSR1", "http://localhost:5001", msr1, {from: owner});

        const service = {
            name: 'Navigational warning', 
            mrn: 'urn:mrn:mcp:service:mcc:core:instance:example', 
            version: '0.1', 
            keywords: 'safety navigation', 
            coverageArea: 'POLYGON((10.689 -25.092, 34.595 -20.170, 38.814 -35.639, 13.502 -39.155, 10.689 -25.092))', 
            implementsDesignMRN: 'urn:mrn:mcp:service:mcc:core:design:example', 
            implementsDesignVersion: '0.1',
            msr: {
                name: '',
                url: ''
            }
        };
        await this.msrContract.registerServiceInstance(service, service.keywords.split(" "), {from: msr1});

        array = await this.msrContract.getServiceInstances({from: other});
        console.log(array);
        expect(array.length == 1);
    });
});