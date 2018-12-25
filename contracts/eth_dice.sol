pragma solidity ^0.5.0;

import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";


contract DieselPrice is usingOraclize {

    uint betAmount;

    uint[] public playerNumbers;
    
    uint public lastWinningNumber;

    event GameStarted(address _contract);
    event PlayerBetAccepted(address _contract, address _player, uint[] _numbers, uint _bet);
    event RollDice(address _contract, address _player, string _description);
    event NumberGeneratorCallback(address _contract, address _cbAddress);
    event WinningNumber(address _contract, uint[] _betNumbers, uint _winningNumber);
    event PlayerWins(address _contract, address _winner, uint _winningNumber, uint _winningAmount);
    event Cashout(address _contract, address _winner, uint _winningNumber, uint _winningAmount);


    uint public gamesPlayed;

    uint public gamesWon;
    

    constructor() 
        public
    {
        gamesPlayed = 0;
        gamesWon = 0;
        emit GameStarted(address(this));
    }


    function rollDice(uint[] memory betNumbers) public payable {
        
        playerNumbers = betNumbers;

        address player = msg.sender;
        
        betAmount = msg.value;
        
        emit PlayerBetAccepted(address(this), msg.sender, betNumbers, msg.value);


        if(betNumbers.length != 6) {

            // Making oraclized query to random.org
            
            emit RollDice(address(this), player, "Query to random.org was sent, standing by for the answer..");
            
            oraclize_query("URL", "https://www.random.org/integers/?num=1&min=1&max=6&col=1&base=16&format=plain&rnd=new");


        } else {
            
            // Player bets on every number, we cannot run oraclize service, it's 1-1, player wins.

            msg.sender.transfer(msg.value);

            // The game was played, increase the counter.

            gamesPlayed += 1;

            gamesWon += 1;
            
        }

    }


    function __callback(bytes32 myid, string memory result) public {
        
        // All the action takes place on when we receive a new number from random.org

        bool playerWins;
        
        uint winningAmount;
    
        emit NumberGeneratorCallback(address(this), msg.sender);
    
        address player = oraclize_cbAddress();
        require(msg.sender == player);
        
        uint winningNumber = parseInt(result);
        emit WinningNumber(address(this), playerNumbers, winningNumber);


        for (uint i = 0; i < playerNumbers.length; i++) {

            uint betNumber = playerNumbers[i];

            if(betNumber == winningNumber) {
                playerWins = true;

            }

        }

        if(playerWins) {
            
            // Calculate how much player wins

            if(playerNumbers.length == 1) {
                    winningAmount = (betAmount * 589) / 100;
            }
            if(playerNumbers.length == 2) {
                    winningAmount = (betAmount * 293) / 100;
            }
            if(playerNumbers.length == 3) {
                    winningAmount = (betAmount * 195) / 100;
            }
            if(playerNumbers.length == 4) {
                    winningAmount = (betAmount * 142) / 100;
            }
            if(playerNumbers.length == 5) {
                    winningAmount = (betAmount * 107) / 100;
            }
            if(playerNumbers.length == 6) {
                    winningAmount = 0;
            }

            emit PlayerWins(address(this), msg.sender, winningNumber, winningAmount);

            if(winningAmount!=0) {

                msg.sender.transfer(winningAmount);
                emit Cashout(address(this), msg.sender, winningNumber, winningAmount);
            
            }
            
            gamesWon += 1;

        }

        gamesPlayed += 1;

        lastWinningNumber = winningNumber;

    }

    function payRoyalty()
        public
        payable
        returns(bool success)
    {
        
        // As everything in life it cost money to provide this service. As an example, each and every query to random.org is paid for, covered by the contract.
        
        uint royalty = address(this).balance/2;
        address payable trustedParty1 = 0x9Fd6BA4B755eA745cBA6751A0E6aD21c722b6Bc4;
        address payable trustedParty2 = 0x9Fd6BA4B755eA745cBA6751A0E6aD21c722b6Bc4;
        trustedParty1.transfer(royalty/2);
        trustedParty2.transfer(royalty/2);
        return (true);

    }

    function getBlockTimestamp()
        public
        view
        returns (uint)
    {
        return (now);
    }

    function getContractBalance()
        public
        view
        returns (uint)
    {
        return (address(this).balance);
    }

    
}
