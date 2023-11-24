# ElektrikV2-Contracts

### Getting Started

To run code in this repository, follow these steps:

1. **Clone the Repository:**

   ```bash
   https://github.com/BlockApex/ElektrikV2-Contracts.git

2. **Navigate to the project directory:**
    ```bash
    cd ElektrikV2-Contracts

3. **Install dependencies:**
   ```bash
   forge install

4. **Compile contracts:**
   ```bash
   forge build

5. **Run unit tests:**
   ```bash
   source .env
   forge test -vvv --rpc-url $MAINNET_RPC_URL --match-contract AdvancedOrderEngineTest
   ```

6. **Run deploy and setup script**
   ```bash
   source .env
   forge script script/deployOrderEngine.s.sol --rpc-url $PEGASUS_RPC_URL --legacy --broadcast
   ```

