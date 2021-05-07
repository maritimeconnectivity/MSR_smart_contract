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
    address[] private _msrs;

    struct ServiceSpecification {
        string name;
        string mrn;
        string version;
        string[] keywords;
        Msr msr;
    }

    struct ServiceSpecificationInternal {
        string name;
        string mrn;
        string version;
        string[] keywords;
        string uid;
        bytes32 uidHash;
        address msr;
    }

    mapping(string => string[]) private _serviceSpecificationKeywordIndex;
    mapping(string => ServiceSpecificationInternal) private _serviceSpecifications;
    string[] private _serviceSpecificationKeys;
    event ServiceSpecAdded(ServiceSpecification);

    struct ServiceDesign {
        string name;
        string mrn;
        string version;
        string implementsSpecificationMRN;
        string implementsSpecificationVersion;
        Msr msr;
    }

    struct ServiceDesignInternal {
        string name;
        string mrn;
        string version;
        string implementsSpecificationMRN;
        string implementsSpecificationVersion;
        bytes32 specUidHash;
        string uid;
        bytes32 uidHash;
        address msr;
    }

    mapping(string => ServiceDesignInternal) private _serviceDesigns;
    string[] private _serviceDesignKeys;
    event ServiceDesignAdded(ServiceDesign);

    struct ServiceInstance {
        string name;
        string mrn;
        string version;
        string[] keywords;
        string coverageArea;
        string implementsDesignMRN;
        string implementsDesignVersion;
        Msr msr;
    }

    struct ServiceInstanceInternal {
        string name;
        string mrn;
        string version;
        string[] keywords;
        string coverageArea;
        string implementsDesignMRN;
        string implementsDesignVersion;
        bytes32 designUidHash;
        string uid;
        bytes32 uidHash;
        address msr;
    }

    mapping(string => string[]) private _serviceInstanceKeywordIndex;
    string[] private _serviceInstanceKeys;
    mapping(string => ServiceInstanceInternal) private _serviceInstances;
    event ServiceInstanceAdded(ServiceInstance);

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
        _msrs.push(account);
    }

    function getMsrs() public view returns (Msr[] memory) {
        Msr[] memory msrs = new Msr[](_msrs.length);
        for (uint i = 0; i < _msrs.length; i++) {
            Msr storage msr = _msrMapping[_msrs[i]];
            msrs[i] = msr;
        }
        return msrs;
    }

    function getEndorsers() public view returns (Endorser[] memory) {
        return _endorsers;
    }

    function getServiceSpecifications() public view returns (ServiceSpecification[] memory) {
        ServiceSpecification[] memory serviceSpecs = new ServiceSpecification[](_serviceSpecificationKeys.length);
        for (uint i = 0; i < _serviceSpecificationKeys.length; i++) {
            ServiceSpecificationInternal storage s = _serviceSpecifications[_serviceSpecificationKeys[i]];
            serviceSpecs[i] = ServiceSpecification({name: s.name, mrn: s.mrn, version: s.version, keywords: s.keywords, msr: _msrMapping[s.msr]});
        }
        return serviceSpecs;
    }

    function getServiceSpecificationsByKeyword(string calldata keyword) public view returns (ServiceSpecification[] memory) {
        string[] storage specKeys = _serviceSpecificationKeywordIndex[keyword];
        ServiceSpecification[] memory serviceSpecs = new ServiceSpecification[](specKeys.length);

        for (uint i = 0; i < specKeys.length; i++) {
            ServiceSpecificationInternal storage s = _serviceSpecifications[specKeys[i]];
            serviceSpecs[i] = ServiceSpecification({name: s.name, mrn: s.mrn, version: s.version, keywords: s.keywords, msr: _msrMapping[s.msr]});
        }

        return serviceSpecs;
    }

    function registerServiceSpecification(string calldata name, string calldata mrn, string calldata version, string[] calldata keywords) public {
        require(hasRole(MSR_ROLE, msg.sender), "You do not have permission to register service specifications!");

        string memory uid = string(bytes.concat(bytes(mrn), bytes(version)));
        require(bytes(_serviceSpecifications[uid].uid).length == 0, "Service specification already exists!");

        bytes32 uidHash = keccak256(abi.encodePacked(uid));
        ServiceSpecificationInternal memory serviceSpecification = ServiceSpecificationInternal({name: name, mrn: mrn, version: version, keywords: keywords, uid: uid, uidHash: uidHash, msr: msg.sender});
        _serviceSpecificationKeys.push(uid);
        _serviceSpecifications[uid] = serviceSpecification;

        for (uint i = 0; i < keywords.length; i++) {
            _serviceSpecificationKeywordIndex[keywords[i]].push(uid);
        }
        ServiceSpecification memory spec = ServiceSpecification({name: name, mrn: mrn, version: version, keywords: keywords, msr: _msrMapping[msg.sender]});
        emit ServiceSpecAdded(spec);
    }
    
    function getServiceDesigns() public view returns (ServiceDesign[] memory) {
        ServiceDesign[] memory designs = new ServiceDesign[](_serviceDesignKeys.length);

        for (uint i = 0; i < _serviceDesignKeys.length; i++) {
            ServiceDesignInternal storage d = _serviceDesigns[_serviceDesignKeys[i]];
            designs[i] = ServiceDesign({name: d.name, mrn: d.mrn, version: d.version, implementsSpecificationMRN: d.implementsSpecificationMRN, implementsSpecificationVersion: d.implementsSpecificationVersion, msr: _msrMapping[d.msr]});
        }

        return designs;
    }

    /**
     * Returns an array of all service designs that implement a given specification
     */
    function getServiceDesigns(string calldata specificationMRN, string calldata specificationVersion) public view returns (ServiceDesign[] memory) {
        bytes memory specUid = bytes.concat(bytes(specificationMRN), bytes(specificationVersion));
        bytes32 specUidHash = keccak256(abi.encodePacked(specUid));
        
        uint count = 0;
        for (uint i = 0; i < _serviceDesignKeys.length; i++) {
            ServiceDesignInternal storage d = _serviceDesigns[_serviceDesignKeys[i]];
            if (specUidHash == d.specUidHash) {
                count++;
            }
        }
        ServiceDesign[] memory designs = new ServiceDesign[](count);
        for (uint i = 0; i < _serviceDesignKeys.length; i++) {
            ServiceDesignInternal storage d = _serviceDesigns[_serviceDesignKeys[i]];
            if (specUidHash == d.specUidHash) {
                designs[i] = ServiceDesign({name: d.name, mrn: d.mrn, version: d.version, implementsSpecificationMRN: d.implementsSpecificationMRN, implementsSpecificationVersion: d.implementsSpecificationVersion, msr: _msrMapping[d.msr]});
            }
        }
        
        return designs;
    }

    function registerServiceDesign(ServiceDesign memory design) public {
        require(hasRole(MSR_ROLE, msg.sender), "You do not have permission to register service designs!");
        
        string memory uid = string(bytes.concat(bytes(design.mrn), bytes(design.version)));
        require(bytes(_serviceDesigns[uid].uid).length == 0, "Service design already exists!");

        string memory specUid = string(bytes.concat(bytes(design.implementsSpecificationMRN), bytes(design.implementsSpecificationVersion)));
        bytes32 specUidHash = keccak256(abi.encodePacked(specUid));
        require(_serviceSpecifications[specUid].uidHash == specUidHash, "The implemented specification does not exist.");

        bytes32 uidHash = keccak256(abi.encodePacked(uid));
        ServiceDesignInternal memory designInternal = ServiceDesignInternal({name: design.name, mrn: design.mrn, version: design.version, implementsSpecificationMRN: design.implementsSpecificationMRN, implementsSpecificationVersion: design.implementsSpecificationVersion, specUidHash: specUidHash, uid: uid, uidHash: uidHash, msr: msg.sender});
        _serviceDesignKeys.push(uid);
        _serviceDesigns[uid] = designInternal;

        //ServiceDesign memory d = ServiceDesign({name: name, mrn: mrn, version: version, implementsSpecificationMRN: implementsSpecificationMRN, implementsSpecificationVersion: implementsSpecificationVersion, msr: _msrMapping[msg.sender]});
        design.msr = _msrMapping[msg.sender];
        emit ServiceDesignAdded(design);
    }

    function getServiceInstances() public view returns (ServiceInstance[] memory) {
        ServiceInstance[] memory serviceInstances = new ServiceInstance[](_serviceInstanceKeys.length);
        for (uint i = 0; i < _serviceInstanceKeys.length; i++) {
            ServiceInstanceInternal storage inst = _serviceInstances[_serviceInstanceKeys[i]];
            serviceInstances[i] = ServiceInstance({name: inst.name, mrn: inst.mrn, version: inst.version, keywords: inst.keywords, coverageArea: inst.coverageArea, implementsDesignMRN: inst.implementsDesignMRN, implementsDesignVersion: inst.implementsDesignVersion, msr: _msrMapping[inst.msr]});
        }

        return serviceInstances;
    }

    function getServiceInstancesByKeyword(string calldata keyword) public view returns (ServiceInstance[] memory) {
        string[] storage instanceKeys = _serviceInstanceKeywordIndex[keyword];
        ServiceInstance[] memory serviceInstances = new ServiceInstance[](instanceKeys.length);

        for (uint i = 0; i < instanceKeys.length; i++) {
            ServiceInstanceInternal storage inst = _serviceInstances[instanceKeys[i]];
            serviceInstances[i] = ServiceInstance({name: inst.name, mrn: inst.mrn, version: inst.version, keywords: inst.keywords, coverageArea: inst.coverageArea, implementsDesignMRN: inst.implementsDesignMRN, implementsDesignVersion: inst.implementsDesignVersion, msr: _msrMapping[inst.msr]});
        }

        return serviceInstances;
    }

    function registerServiceInstance(ServiceInstance memory instance) public {
        require(hasRole(MSR_ROLE, msg.sender), "You do not have permission to register service instances!");

        string memory uid = string(bytes.concat(bytes(instance.mrn), bytes(instance.version)));
        require(bytes(_serviceInstances[uid].uid).length == 0, "Service instance already exists!");

        string memory designUid = string(bytes.concat(bytes(instance.implementsDesignMRN), bytes(instance.implementsDesignVersion)));
        bytes32 designUidHash = keccak256(abi.encodePacked(designUid));
        require(_serviceDesigns[designUid].uidHash == designUidHash, "The implemeted design does not exist!");

        bytes32 uidHash = keccak256(abi.encodePacked(uid));
        _serviceInstanceKeys.push(uid);
        _serviceInstances[uid] = ServiceInstanceInternal({name: instance.name, mrn: instance.mrn, version: instance.version, keywords: instance.keywords, coverageArea: instance.coverageArea, implementsDesignMRN: instance.implementsDesignMRN, implementsDesignVersion: instance.implementsDesignVersion, designUidHash: designUidHash, uid: uid, uidHash: uidHash, msr: msg.sender});

        for (uint i = 0; i < instance.keywords.length; i++) {
            _serviceInstanceKeywordIndex[instance.keywords[i]].push(uid);
        }
        instance.msr = _msrMapping[msg.sender];
        emit ServiceInstanceAdded(instance);
    }
}