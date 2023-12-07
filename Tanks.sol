// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity 0.8.19;

import "fhevm/lib/TFHE.sol";
import "hardhat/console.sol";

contract Tanks {
    uint constant public BOARD_SIZE = 4;

    struct Game {
        address player1;
        address player2;
        uint firstPlayerAmount;
        uint secondPlayerAmount;
        bool gameCreated;
        bool gameReady;
        bool gameEnded;
        bool player1Ready;
        bool player2Ready;
        address currentPlayer;
        address winner;
        euint8[BOARD_SIZE][BOARD_SIZE] player1Board;
        euint8[BOARD_SIZE][BOARD_SIZE] player2Board;
    }

    Game[] public games;

    event GameStarted(uint id, address creator, address partner);
    event Attack(uint8 x, uint8 y, address victim, bool hit);
    event GameEnded(uint id, address winner);

    function createGame(address _partner, uint _amount) public {
        require(_amount <= 5);

        Game memory newGame;
        newGame.player1 = msg.sender;
        newGame.player2 = _partner;
        newGame.firstPlayerAmount = _amount;
        newGame.secondPlayerAmount = _amount;
        newGame.gameCreated = true;
        newGame.currentPlayer = msg.sender;

        games.push(newGame);
    }

    function fillTheBoard(uint _id, bytes calldata encryptedValue) public {
        require(games[_id].player1 == msg.sender || games[_id].player2 == msg.sender, "You're stanger");
        require(!games[_id].gameReady);
        require(!games[_id].gameEnded);

        euint32 packedData = TFHE.asEuint32(encryptedValue);
        euint8[BOARD_SIZE][BOARD_SIZE] storage board;
        if (msg.sender == games[_id].player1) {
            board = games[_id].player1Board;
        } else {
            board = games[_id].player2Board;
        }
        euint8 mask = TFHE.asEuint8(1);
        euint8 tanksCount = TFHE.asEuint8(0);


        for (uint256 i = 0; i < BOARD_SIZE * BOARD_SIZE; i++) {
          euint8 value = TFHE.asEuint8(TFHE.and(packedData, mask));
          board[i / BOARD_SIZE][i % BOARD_SIZE] = value;
          tanksCount = TFHE.add(tanksCount, value);

          packedData = TFHE.shr(packedData, uint8(1));
        }

        // Make sure the user created equal amount of tanks
        TFHE.optReq(TFHE.eq(tanksCount, uint8(games[_id].firstPlayerAmount)));

        if (msg.sender == games[_id].player1) {
            games[_id].player1Ready = true;
        } else {
            games[_id].player2Ready = true;
        }

        if (games[_id].player2Ready && games[_id].player1Ready) {
            games[_id].gameReady = true;
            emit GameStarted(_id, games[_id].player1, games[_id].player2);
        }
    }

    function attack(uint _id, uint8[] memory _x, uint8[] memory _y) public {
        require(games[_id].player1 == msg.sender || games[_id].player2 == msg.sender, "You're stanger");
        require(_x.length == _y.length, "Incorrect data");
        require(games[_id].gameReady, "Game not ready");
        require(!games[_id].gameEnded, "Game has ended");
        require(msg.sender == games[_id].currentPlayer, "Not your turn");

        euint8[BOARD_SIZE][BOARD_SIZE] storage targetBoard;
        if (msg.sender == games[_id].player1) {
            targetBoard = games[_id].player2Board;
        } else {
            targetBoard = games[_id].player1Board;
        }

        if (msg.sender == games[_id].player1) {
            require(_x.length == games[_id].firstPlayerAmount);
            for (uint256 i = 0; i < games[_id].firstPlayerAmount; i++) {
                uint8 target = TFHE.decrypt(targetBoard[_x[i]][_y[i]]);
                require(target < 2, "Already attacked this cell");

                if (target == 1) {
                    games[_id].secondPlayerAmount --;
                    emit Attack(_x[i], _y[i], games[_id].player2, true);
                } else {
                    emit Attack(_x[i], _y[i], games[_id].player2, false);
                }
                targetBoard[_x[i]][_y[i]] = TFHE.asEuint8(2);
            }
        } else {
            require(_x.length == games[_id].firstPlayerAmount);
            for (uint256 i = 0; i < games[_id].secondPlayerAmount; i++) {
                uint8 target = TFHE.decrypt(targetBoard[_x[i]][_y[i]]);
                require(target < 2, "Already attacked this cell");

                if (target == 1) {
                    games[_id].firstPlayerAmount --;
                    emit Attack(_x[i], _y[i], games[_id].player1, true);
                } else {
                    emit Attack(_x[i], _y[i], games[_id].player1, false);
                }
                targetBoard[_x[i]][_y[i]] = TFHE.asEuint8(2);
            }
        }

        if (games[_id].currentPlayer == games[_id].player1) {
            games[_id].currentPlayer = games[_id].player2;
        } else {
            games[_id].currentPlayer = games[_id].player1;
        }

        if (games[_id].firstPlayerAmount == 0 || games[_id].secondPlayerAmount == 0) {
            games[_id].gameEnded = true;
            games[_id].winner = msg.sender;
            emit GameEnded(_id, msg.sender);
        }
    }
}