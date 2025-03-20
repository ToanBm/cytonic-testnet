#!/bin/bash
# Logo
curl -s https://raw.githubusercontent.com/ToanBm/user-info/main/logo.sh | bash
sleep 3
show() {
    echo -e "\033[1;35m$1\033[0m"
}

# Step 1: Install hardhat
echo "Install Hardhat..."
npm init -y
echo "Install dotenv..."
npm install dotenv

# Step 2: Automatically choose "Create an empty hardhat.config.js"
echo "Choose >> Create a JavaScript project"
npm install --save-dev hardhat
npx hardhat init

# Step 3: Update hardhat.config.js with the proper configuration
echo "Creating new hardhat.config file..."
rm hardhat.config.js

cat <<'EOF' > hardhat.config.ts
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    cytonicTestnet: {
      url: "https://rpc.evm.testnet.cytonic.com",
      chainId: 52226,
      accounts: [`0x${process.env.PRIVATE_KEY}`] // Lấy private key từ .env
    },
  },
};
EOF

# Step 4: Create MyToken.sol contract
echo "Create ERC20 contract..."
rm contracts/Lock.sol

cat <<'EOF' > contracts/SimpleStorage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 public value;

    function setValue(uint256 _value) external {
        value = _value;
    }
}
EOF



# Step 6: Create .env file for storing private key
echo "Create .env file..."

read -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Step 5: Compile contracts
echo "Compile your contracts..."
npx hardhat compile

# Step 7: Create deploy script
echo "Creating deploy script..."
mkdir scripts

cat <<'EOF' > scripts/deploy.js
async function main() {
  const Contract = await ethers.getContractFactory("MyContract");
  const contract = await Contract.deploy(); // Không cần .deployed() nữa
  console.log("Deploying contract...");
  await contract.waitForDeployment(); // Dùng waitForDeployment() thay vì deployed()
  console.log("Deployed to:", await contract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOF
************************************************************************************
# Step 8: Deploying the smart contract
echo "Do you want to deploy multiple contracts?"
read -p "Enter the number of contracts to deploy: " COUNT

# Validate input (must be a number)
if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
  echo "Please enter a valid number!"
  exit 1
fi

for ((i=1; i<=COUNT; i++))
do
  echo "🚀 Deploying contract $i..."

  # Deploy the contract and extract the contract address
  CONTRACT_ADDRESS=$(yes | npx hardhat ignition deploy ./ignition/modules/deploy.ts --network somnia --reset | grep -oE '0x[a-fA-F0-9]{40}')

  # Check if an address was retrieved
  if [[ -z "$CONTRACT_ADDRESS" ]]; then
    echo "❌ Unable to retrieve contract address!"
    exit 1
  fi

  echo "✅ Contract $i deployed at: $CONTRACT_ADDRESS"
  echo "-----------------------------------"

  # Generate a random wait time between 9-15 seconds
  RANDOM_WAIT=$((RANDOM % 7 + 9))
  echo "⏳ Waiting for $RANDOM_WAIT seconds before deploying the next contract..."
  sleep $RANDOM_WAIT
done

echo "🎉 Successfully deployed $COUNT contracts!"






