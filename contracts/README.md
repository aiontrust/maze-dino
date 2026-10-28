# MAZE DINO NFT (draft, not deployed)

ERC-721 collectible dinos you hatch by paying MAZE. Each dino is an 8-digit DNA number and its artwork is drawn fully on-chain.

- **Hatch:** `approve` MAZE to the contract, then call `hatch()`. Price goes straight to the treasury (your game wallet).
- **Fixed rules:** MAZE address, treasury, price and supply cap are set at deploy time. There is no owner and no admin functions.
- **Starting values:** price 10,000 MAZE (`10000000000000000000000` base units), cap 1,000.
- **Randomness:** DNA comes from block data, which is fine for cosmetic traits but is not tamper-proof. Do not attach real-money value to rare traits.

## Files
- `src/MazeDino.sol` the NFT contract (tokenURI returns JSON with the SVG image embedded)
- `src/DinoRenderer.sol` draws the dino from DNA
- `tools/dino_ref.py` reference renderer; the tests check the on-chain SVG is byte-identical to it
- `test/MazeDino.t.sol` Foundry tests

## Run the tests
```
curl -L https://foundry.paradigm.xyz | bash && foundryup
forge install OpenZeppelin/openzeppelin-contracts@v5.0.2 foundry-rs/forge-std --no-git
python3 tools/dino_ref.py refs
forge test
```

## Before mainnet
Deploy to the Sepolia test network first with a test MAZE token, then verify on Etherscan. Mainnet deployment and every hatch cost ETH gas.
