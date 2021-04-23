// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MsrContract is AccessControl {

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant MSR_ADMIN_ROLE = keccak256("MSR_ADMIN_ROLE");
    bytes32 public constant MSR_ROLE = keccak256("MSR_ROLE");

    struct Endorser {
        string name;
        bytes certificate;
    }

    struct Endorsement {
        Endorser endorser;
        bytes signature;
    }
    
    struct Msr {
        string name;
        string mrn;
        string url;
    }

    mapping(address => Msr) private _msrMapping;
    Msr[] private _msrs;

    struct ServiceSpecification {
        string mrn;
        string version;
        string[] keywords;
        Msr msr;
    }

    mapping(string => ServiceSpecification[]) private _serviceSpecificationKeywordIndex;
    ServiceSpecification[] private _serviceSpecifications;

    struct ServiceDesign {
        string mrn;
        string version;
        string implementsSpecificationMRN;
        Msr msr;
    }

    ServiceDesign[] private _serviceDesigns;

    struct ServiceInstance {
        string mrn;
        string version;
        string[] keywords;
        string coverageArea;
        string implementsDesignMRN;
        Msr msr;
    }

    mapping(string => ServiceInstance[]) private _serviceInstanceKeywordIndex;
    ServiceInstance[] private _serviceInstances;

    Endorser[] private _endorsers;

    constructor() {
        _setupRole(SUPER_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MSR_ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(MSR_ROLE, MSR_ADMIN_ROLE);
    }

    function addMsr(string calldata name, string calldata mrn, string calldata url, address account) public {
        require(hasRole(MSR_ADMIN_ROLE, msg.sender), "You need to be an MSR admin to do this!");
        grantRole(MSR_ROLE, account);
        Msr memory msr = Msr({name: name, mrn: mrn, url: url});
        _msrMapping[account] = msr;
        _msrs.push(_msrMapping[account]);
    }

    function getMsrs() public view returns (Msr[] memory) {
        return _msrs;
    }

    function getEndorsers() public view returns (Endorser[] memory) {
        return _endorsers;
    }

    function getServiceSpecifications() public view returns (ServiceSpecification[] memory) {
        return _serviceSpecifications;
    }

    function getServiceSpecifications(string calldata keyword) public view returns (ServiceSpecification[] memory) {
        return _serviceSpecificationKeywordIndex[keyword];
    }

    function registerServiceSpecification(string calldata mrn, string calldata version, string[] calldata keywords) public {
        require(hasRole(MSR_ROLE, msg.sender), "You do not have permission to register service specifications!");
        Msr storage msr = _msrMapping[msg.sender];
        ServiceSpecification memory serviceSpecification = ServiceSpecification({mrn: mrn, version: version, keywords: keywords, msr: msr});
        _serviceSpecifications.push(serviceSpecification);
        ServiceSpecification storage _spec = _serviceSpecifications[_serviceSpecifications.length - 1];

        for (uint i = 0; i < serviceSpecification.keywords.length; i++) {
            _serviceSpecificationKeywordIndex[serviceSpecification.keywords[i]].push(_spec);
        }
    }
    
    function getServiceDesigns() public view returns (ServiceDesign[] memory) {
        return _serviceDesigns;
    }

    /**
     * Returns an array of all service designs that implement a given specification
     */
    function getServiceDesigns(string calldata specificationMRN) public view returns (ServiceDesign[] memory) {
        bytes32 hash = keccak256(abi.encodePacked(specificationMRN));
        uint count = 0;
        for (uint i = 0; i < _serviceDesigns.length; i++) {
            ServiceDesign storage design = _serviceDesigns[i];
            string storage specMRN = design.implementsSpecificationMRN;
            if (hash == keccak256(abi.encodePacked(specMRN))) {
                count++;
            }
        }
        ServiceDesign[] memory designs = new ServiceDesign[](count);
        for (uint i = 0; i < _serviceDesigns.length; i++) {
            ServiceDesign storage design = _serviceDesigns[i];
            string storage specMRN = design.implementsSpecificationMRN;
            if (hash == keccak256(abi.encodePacked(specMRN))) {
                designs[i] = design;
            }
        }
        
        return designs;
    }

    function registerServiceDesign(ServiceDesign calldata serviceDesign) public {
        require(hasRole(MSR_ADMIN_ROLE, msg.sender), "You do not have permission to register service designs!");
        _serviceDesigns.push(serviceDesign);
    }
}