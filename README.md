# MSR smart contract

A smart contract for the MSR ledger

## Deployment of the contract to a local environment

Our implementation is based on the [Ethereum blockchain](https://ethereum.org/en/) and [Hyperledger Besu](https://www.hyperledger.org/use/besu) as an Ethereum protocol client.

We encourage to use [the ConsenSys Quorum](https://consensys.net/quorum/products/guides/getting-started-with-consensys-quorum/) for test purpose.

In order to run our smart contract over the Ethereum blockchain, the local blockchain network should be up and running beforehand.

Please follow [the deployment guideline of the quorum-test-network](https://consensys.net/quorum/products/guides/getting-started-with-consensys-quorum/) to deploy.

When the network is online, deploy the smart contract by the command below::

```
npm run migrate
```  
