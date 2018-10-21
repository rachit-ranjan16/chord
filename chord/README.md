# Chord
### Description 
Implement Chord Protocol with Distributed Hash Tables for O(log m) lookup  

## Group Members 
  - **Rachit Ranjan** 
  - **Aditya Vashist** 

## Prerequisites 
  - Elixir 1.7+ Installation  

## Execution Instructions 
  - Navigate to `chord`  
  - Compile and Build 
    - `mix compile`
    - `mix run` 
    - `mix escript.build`
  - Execute 
    - `./chord numNodes numRequests` 
      - `numNodes`: Integer 
      - `numRequests`: Integer
  - Key Terms in the generated logs 
    - `initiate`: Node will start firing `numRequests` lookups
    - `Lookup`: A node in chord ring has received a request from another node to lookup a key 
    - `Notify`: Node that initiated a lookup request received an async ack that the key has been found in the ring 
    - `Converged`: All `numNodes` have made `numRequest` lookups and the calls succeeded
  - Main Process will exit after convergence 

## Observations 
  - Largest Network 
    - `numNodes` = 10000
    - `numRequests` = 100 