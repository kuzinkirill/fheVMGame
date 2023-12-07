# fheVMGame
Deploying the game "Tanks" using Fully Homomorphic Encryption

## Description

We are the team of FileMarket and we work on transfering access to encrypted data between peers onchain. We are extremelly excited about FHE and how it could it improve the UX on our platform keeping the privacy and decentralization on the high level. The hackathon project is our initial step in diving into the FHE through Inco chain and a discovery of how we could integrate Inco Chain into Filemarket.

During this hackathon we have created a smartcontract for the game "Tanks" and the idea of it is similar to the Battleships, but is different. We developed a smart contract, which allows to create various game sessions and join them using a unique id. A creator defines the limit of tanks for the game (5 and less) and an address of another player. After that players can set their tanks on the game board. The number of tanks the player has on the board determines the number of shots they can take at the opponent. As soon as a tank is destroyed, the subsequent number of turns decreases. The game ends when one of the players runs out of the tanks.

Actually our original idea was to be able to transfer the key to the encrypted file with uniques fhEVM functions, but due to uin32 it was not possible at the current stage and therefore we decided to build something, what could work already right now. fhEVM LFG !!!
