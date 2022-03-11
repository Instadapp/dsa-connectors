const { ethers } = require("hardhat");
const {hexlify} =  require('ethers-utils');
const EthUtil = require('ethereumjs-util')
const { soliditySha3 } = require("web3-utils");
const dotenv = require('dotenv');
dotenv.config();

const { expect } = require("chai");

const private_key ='0x' + process.env.PRIVATE_KEY;

// Please note that the public address should correspond to the PRIVATE_KEY in .env file to make the test run succesfully.
const public_address = "0x3Fc046bdE274Fe8Ed2a7Fd008cD9DEB2540dfE36"; 
const deadline = 1000000000000;
const value = 10000000;

describe("starting tests for dai", function () {
    let account_with_funds;
    let my_account;
    let owner;
    let contract1;
    let our_deployed_contract;
    let aave_token_address="0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9";
    let dai_token_address = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    let address_having_aave_tokens = "0xddfAbCdc4D8FfC6d5beaf154f18B778f892A0740";
    let address_having_no_aave_tokens = public_address;
    let contract;

  
    before(async () =>{

      //deploying the main contract
      owner = await ethers.getSigners();
      contract1 = await ethers.getContractFactory("permit_erc20");
      our_deployed_contract = await contract1.deploy();
      await our_deployed_contract.deployed();

      // impersonating a acccount that has some AAVE tokens
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [address_having_aave_tokens],
      });
      account_with_funds=await ethers.getSigner(address_having_aave_tokens);

      //impersonating my account, i have the private key of it
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [address_having_no_aave_tokens],
      });
      my_account=await ethers.getSigner(address_having_no_aave_tokens);

      //giving myself some transaction fee
      await network.provider.send("hardhat_setBalance", [
        address_having_no_aave_tokens,
        "0x1000000000000000000000000000000000",
      ]);    // will need to remove this, this is so that i can make transactions locally as i have no eth


      //creating instance of the AAVE token contract
      aave_token_contract = await ethers.getContractAt("ERC20_functions", dai_token_address);
      

      // needed for getting public variables necessary for hashing
      const abi_contract = [{"inputs":[{"internalType":"uint256","name":"chainId_","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"guy","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":true,"inputs":[{"indexed":true,"internalType":"bytes4","name":"sig","type":"bytes4"},{"indexed":true,"internalType":"address","name":"usr","type":"address"},{"indexed":true,"internalType":"bytes32","name":"arg1","type":"bytes32"},{"indexed":true,"internalType":"bytes32","name":"arg2","type":"bytes32"},{"indexed":false,"internalType":"bytes","name":"data","type":"bytes"}],"name":"LogNote","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"src","type":"address"},{"indexed":true,"internalType":"address","name":"dst","type":"address"},{"indexed":false,"internalType":"uint256","name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":true,"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"burn","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"guy","type":"address"}],"name":"deny","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"mint","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"src","type":"address"},{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"move","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"holder","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"nonce","type":"uint256"},{"internalType":"uint256","name":"expiry","type":"uint256"},{"internalType":"bool","name":"allowed","type":"bool"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"pull","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"usr","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"push","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"guy","type":"address"}],"name":"rely","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"src","type":"address"},{"internalType":"address","name":"dst","type":"address"},{"internalType":"uint256","name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"wards","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}];
      contract = new web3.eth.Contract(abi_contract, dai_token_address)
  
    });

    
    describe("tests", function(){
        it("testing_balance", async function(){
            
            await aave_token_contract.connect(account_with_funds).approve(my_account.address,value);
            await aave_token_contract.connect(my_account).transferFrom(account_with_funds.address,my_account.address,value);

            expect(await aave_token_contract.balanceOf(my_account.address)).to.equal(value);
            expect(await aave_token_contract.balanceOf(our_deployed_contract.address)).to.equal(0);

            // Some Account with the funds gave my account some funds and now those funds will be deposited to our deployed contract using "depositWithPermit" function
        });
        
        
        it("creating hash, signing, calling permit, transfer", async function(){

            //getting the parameters which will be used to generate data hash
            let PERMIT_TYPEHASH = await contract.methods.PERMIT_TYPEHASH().call();
            let currentValidNonce = await contract.methods.nonces(my_account.address).call();
            let DOMAIN_SEPARATOR = await contract.methods.DOMAIN_SEPARATOR().call();

            // generating the hash to sign using private key, the hash will be similar to the one that will be sent as a message in permit function 
            const encoded = web3.eth.abi.encodeParameters(['bytes32', 'address', 'address', 'uint256', 'uint256', 'bool'],[PERMIT_TYPEHASH, my_account.address, our_deployed_contract.address, currentValidNonce, deadline, true]);
            const hash = web3.utils.keccak256(encoded, {encoding: 'hex'});

            const hash1_for_encodePacked = soliditySha3('\x19\x01', DOMAIN_SEPARATOR, hash);
            console.log("The hash that will be signed using private key: ", hash1_for_encodePacked);


            //getting the r ,s ,v from the signature which will be passed as arguments in permit function
            const { v, r, s } = EthUtil.ecsign(Buffer.from(hash1_for_encodePacked.slice(2), 'hex'), Buffer.from(private_key.slice(2), 'hex'));

            //the sender calls permit function to take the allowance of fund transfer from the my_account(me) (Remember that they were interchanged)
            await our_deployed_contract.depositWithPermit(dai_token_address,my_account.address,currentValidNonce,value,deadline,v, hexlify(r), hexlify(s));


            //getting the finla balances
            expect(await aave_token_contract.balanceOf(my_account.address)).to.equal(0);
            expect(await aave_token_contract.balanceOf(our_deployed_contract.address)).to.equal(value);
            console.log("The funds have been deposited to our contract through depositWithPermit function");
        });

    });
  
  });