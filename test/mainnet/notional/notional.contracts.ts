
const NOTIONAL_CONTRACT_ADDRESS = '0x1344A36A1B56144C3Bc62E7757377D288fDE0369';
const NOTIONAL_CONTRACT_ABI = [
    {
        "inputs": [
            {
                "internalType": "uint16",
                "name": "currencyId",
                "type": "uint16"
            },
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "getAccountBalance",
        "outputs": [
            {
                "internalType": "int256",
                "name": "cashBalance",
                "type": "int256"
            },
            {
                "internalType": "int256",
                "name": "nTokenBalance",
                "type": "int256"
            },
            {
                "internalType": "uint256",
                "name": "lastClaimTime",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "getAccountPortfolio",
        "outputs": [
            {
                "components": [
                    {
                        "internalType": "uint256",
                        "name": "currencyId",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "maturity",
                        "type": "uint256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "assetType",
                        "type": "uint256"
                    },
                    {
                        "internalType": "int256",
                        "name": "notional",
                        "type": "int256"
                    },
                    {
                        "internalType": "uint256",
                        "name": "storageSlot",
                        "type": "uint256"
                    },
                    {
                        "internalType": "enum AssetStorageState",
                        "name": "storageState",
                        "type": "uint8"
                    }
                ],
                "internalType": "struct PortfolioAsset[]",
                "name": "",
                "type": "tuple[]"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    }
];

const SNOTE_CONTRACT_ADDRESS = '0x38de42f4ba8a35056b33a746a6b45be9b1c3b9d2';

const WETH_TOKEN_ADDRESS = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const DAI_TOKEN_ADDRESS = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const CDAI_TOKEN_ADDRESS = "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643";
const CETH_TOKEN_ADDRESS = "0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5";
const BPT_TOKEN_ADDRESS = "0x5122E01D819E58BB2E22528c0D68D310f0AA6FD7";
const NOTE_TOKEN_ADDRESS = "0xCFEAead4947f0705A14ec42aC3D44129E1Ef3eD5";
const ERC20_TOKEN_ABI = [
    "function transfer(address _to, uint256 _value) public returns (bool success)",
    "function balanceOf(address account) external view returns (uint256)",
    "function approve(address spender, uint256 amount) external returns (bool)",
];

export default {
    NOTIONAL_CONTRACT_ADDRESS,
    NOTIONAL_CONTRACT_ABI,
    SNOTE_CONTRACT_ADDRESS,
    WETH_TOKEN_ADDRESS,
    BPT_TOKEN_ADDRESS,
    DAI_TOKEN_ADDRESS,
    CDAI_TOKEN_ADDRESS,
    CETH_TOKEN_ADDRESS,
    NOTE_TOKEN_ADDRESS,
    ERC20_TOKEN_ABI
};
