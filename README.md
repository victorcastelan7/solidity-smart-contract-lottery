# Smart Contract Lottery (Solidity + Foundry)

A Chainlink VRF-powered lottery / raffle smart contract built with Foundry.  
Includes configurable parameters, deploy scripts, and tests.

> **Tech stack:** Solidity, Foundry, Chainlink VRF, (add Automation if you use it)

---

## ✨ Features

- **Configurable Lottery**
  - Ticket price, interval, player limit (customize based on your implementation)
- **Secure Randomness (VRF)**
  - Uses Chainlink VRF for unbiased winner selection
- **Automation-Friendly**
  - (If applicable) Designed to work with Chainlink Automation / keepers
- **Deploy & Interaction Scripts**
  - `DeployRaffle.s.sol` – deploys the contract by network
  - `HelperConfig.s.sol` – network-specific config (VRF, subscription, gas lanes)
  - `Interactions.s.sol` – helper functions to enter, draw, etc.

---

## Project Structure

```text
src/
  Raffle.sol          # Core lottery contract

test/
  Raffle.t.sol        # Unit tests
  RaffleIntegration.t.sol  # Integration / fork tests (if applicable)

script/
  DeployRaffle.s.sol  # Deployment
  HelperConfig.s.sol  # Config per chain
  Interactions.s.sol  # Interaction helpers

lib/
  ...                 # Dependencies (e.g. OpenZeppelin, Chainlink)

foundry.toml          # Foundry config
.gitignore            # Pro ignores for artifacts, OS junk, env, etc.
```
