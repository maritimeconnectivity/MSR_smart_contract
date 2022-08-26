# MSR smart contract

A smart contract for the MSR ledger

## Deployment of the contract to a local environment

Our implementation is based on the [Ethereum blockchain](https://ethereum.org/en/) and [Hyperledger Besu](https://www.hyperledger.org/use/besu) as an Ethereum protocol client.

In order to run our smart contract over the Ethereum blockchain, the local blockchain network should be up and running beforehand.

Please follow [the deployment guideline of a Besu test network](https://besu.hyperledger.org/en/stable/private-networks/tutorials/quickstart/#prerequisites) to deploy.

When the network is online, deploy the smart contract by the command below::

```
npm run migrate
```  
