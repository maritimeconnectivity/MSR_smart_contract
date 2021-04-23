const { expect } = require('chai');
const { BN, expectEvent, expectRevert } =  require('@openzeppelin/test-helpers');

const MsrContract = artifacts.require("MsrContract");

contract('MsrContract', ([owner, other]) => {
    beforeEach(async () => {
        this.msrContract = await MsrContract.new({from: owner});
        await this.msrContract.grantRole(await this.msrContract.MSR_ADMIN_ROLE(), owner, {from: owner});
    });

    it('Gets the list of service specifications', async() => {
        const array = await this.msrContract.getServiceSpecifications({from: other});
        expect(array.length == 0);
    });

    it('creates a service specification', async() => {
        let array = await this.msrContract.getServiceSpecifications({from: other});
        expect(array.length == 0);

        await this.msrContract.registerServiceSpecification({from: owner});

        array = await this.msrContract.getServiceSpecifications({from: other});
        console.log(array);
        expect(array.length == 1);
    });
});