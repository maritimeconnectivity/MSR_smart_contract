// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract MsrContract is AccessControl {

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant MSR_ADMIN_ROLE = keccak256("MSR_ADMIN_ROLE");
    bytes32 public constant MSR_ROLE = keccak256("MSR_ROLE");

    struct Msr {
        string name;
        string url;
    }

    mapping(address => Msr) private _msrMapping;
    address[] private _msrs;

    enum InstanceStatus { Provisional, Released, Deprecated, Deleted }

    struct ServiceInstance {
        string name;
        string mrn;
        string version;
        string keywords;
        string coverageArea;
        InstanceStatus status;
        string implementsDesignMRN;
        string implementsDesignVersion;
        Msr msr;
    }

    struct ServiceInstanceInternal {
        string name;
        string mrn;
        string version;
        string keywords;
        string coverageArea;
        string implementsDesignMRN;
        string implementsDesignVersion;
        InstanceStatus status;
        string uid;
        bytes32 uidHash;
        address msr;
    }

    mapping(string => string[]) private _serviceInstanceKeywordIndex;
    mapping(bytes => string[]) private _serviceInstanceByDesignIndex;
    mapping(address => string[]) private _serviceInstancesByMsrIndex;
    string[] private _serviceInstanceKeys;
    mapping(string => ServiceInstanceInternal) private _serviceInstances;
    event ServiceInstanceAdded(ServiceInstance serviceInstance);

    constructor() {
        _setupRole(SUPER_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MSR_ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(MSR_ROLE, MSR_ADMIN_ROLE);
    }

    function addMsr(string calldata name, string calldata url, address account) public {
        require(hasRole(MSR_ADMIN_ROLE, msg.sender), "You need to be an MSR admin to do this!");
        Msr storage tmp = _msrMapping[account];
        require(bytes(tmp.name).length == 0, "MSR already exists!");
        grantRole(MSR_ROLE, account);
        Msr memory msr = Msr({name: name, url: url});
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

    function getServiceInstances() public view returns (ServiceInstance[] memory) {
        ServiceInstance[] memory serviceInstances = new ServiceInstance[](_serviceInstanceKeys.length);
        for (uint i = 0; i < _serviceInstanceKeys.length; i++) {
            ServiceInstanceInternal storage inst = _serviceInstances[_serviceInstanceKeys[i]];
            serviceInstances[i] = ServiceInstance({name: inst.name, mrn: inst.mrn, version: inst.version, keywords: inst.keywords, coverageArea: inst.coverageArea, implementsDesignMRN: inst.implementsDesignMRN, implementsDesignVersion: inst.implementsDesignVersion, status: inst.status, msr: _msrMapping[inst.msr]});
        }

        return serviceInstances;
    }

    function getServiceInstancesByKeyword(string calldata keyword) public view returns (ServiceInstance[] memory) {
        string[] storage instanceKeys = _serviceInstanceKeywordIndex[keyword];
        ServiceInstance[] memory serviceInstances = new ServiceInstance[](instanceKeys.length);

        for (uint i = 0; i < instanceKeys.length; i++) {
            ServiceInstanceInternal storage inst = _serviceInstances[instanceKeys[i]];
            serviceInstances[i] = ServiceInstance({name: inst.name, mrn: inst.mrn, version: inst.version, keywords: inst.keywords, coverageArea: inst.coverageArea, implementsDesignMRN: inst.implementsDesignMRN, implementsDesignVersion: inst.implementsDesignVersion, status: inst.status, msr: _msrMapping[inst.msr]});
        }

        return serviceInstances;
    }

    function getServiceInstancesByDesign(string calldata designMRN, string calldata designVersion) public view returns (ServiceInstance[] memory) {
        bytes memory designUid = bytes.concat(bytes(designMRN), bytes(designVersion));
        string[] storage instanceKeys = _serviceInstanceByDesignIndex[designUid];

        ServiceInstance[] memory serviceInstances = new ServiceInstance[](instanceKeys.length);

        for (uint i = 0; i < instanceKeys.length; i++) {
            ServiceInstanceInternal storage inst = _serviceInstances[instanceKeys[i]];
            serviceInstances[i] = ServiceInstance({name: inst.name, mrn: inst.mrn, version: inst.version, keywords: inst.keywords, coverageArea: inst.coverageArea, implementsDesignMRN: inst.implementsDesignMRN, implementsDesignVersion: inst.implementsDesignVersion, status: inst.status, msr: _msrMapping[inst.msr]});
        }

        return serviceInstances;
    }

    function registerServiceInstance(ServiceInstance memory instance, string[] calldata keywords) public {
        require(hasRole(MSR_ROLE, msg.sender), "You do not have permission to register service instances!");

        string memory uid = string(bytes.concat(bytes(instance.mrn), bytes(instance.version)));
        require(bytes(_serviceInstances[uid].uid).length == 0, "Service instance already exists!");

        bytes32 uidHash = keccak256(abi.encodePacked(uid));
        _serviceInstanceKeys.push(uid);
        _serviceInstances[uid] = ServiceInstanceInternal({name: instance.name, mrn: instance.mrn, version: instance.version, keywords: instance.keywords, coverageArea: instance.coverageArea, implementsDesignMRN: instance.implementsDesignMRN, implementsDesignVersion: instance.implementsDesignVersion, status: instance.status, uid: uid, uidHash: uidHash, msr: msg.sender});

        bytes memory keywordsConcat = "";
        for (uint i = 0; i < keywords.length; i++) {
            _serviceInstanceKeywordIndex[keywords[i]].push(uid);
            keywordsConcat = bytes.concat(keywordsConcat, bytes(keywords[i]));
            if (i != keywords.length - 1) {
                keywordsConcat = bytes.concat(keywordsConcat, bytes(" "));
            }
        }

        string memory keywordsConcatString = string(keywordsConcat);
        _serviceInstances[uid].keywords = keywordsConcatString;

        bytes memory designUid = bytes.concat(bytes(instance.implementsDesignMRN), bytes(instance.implementsDesignVersion));
        _serviceInstanceByDesignIndex[designUid].push(uid);
        _serviceInstancesByMsrIndex[msg.sender].push(uid);

        instance.msr = _msrMapping[msg.sender];
        instance.keywords = keywordsConcatString;
        emit ServiceInstanceAdded(instance);
    }

    function changeInstanceStatus(string calldata instanceMrn, string calldata instanceVersion, InstanceStatus newStatus) public {
        string memory uid = string(bytes.concat(bytes(instanceMrn), bytes(instanceVersion)));
        require(hasRole(MSR_ROLE, msg.sender) && (msg.sender == _serviceInstances[uid].msr), "You do not have permission to change the status of this instance!");

        _serviceInstances[uid].status = newStatus;
    }

    function deleteMsr(address msrAddress) public {
        require(hasRole(MSR_ADMIN_ROLE, msg.sender), "You do not have permission to delete the MSR!");
        revokeRole(MSR_ROLE, msrAddress);
        for (uint i = 0; i < _serviceInstancesByMsrIndex[msrAddress].length; i++) {
            _serviceInstances[_serviceInstancesByMsrIndex[msrAddress][i]].status = InstanceStatus.Deleted;
        }
    }
}