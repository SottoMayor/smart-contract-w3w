// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/*
    Vulnerabilidades:
    A => Timestamp: condição perigosa baseada em block.timestamp
    B => Reentrancy: transferência ocorre antes da atualização do estado
    C => Erro de lógica de negócio: a propriedade open deveria ser setada como false.
    D => Manipulação de Array: Não verificar corretamente os limites do array
    E => Suicidal: qualquer um pode pode destruir o contrato
    F => Utilização de função depreciada
*/

contract FloodHelp {
    // Payload de entrada
    struct Request {
        uint id;
        address author; // Endereço da carteira do autor do pedido, para quem as moedas vão.
        string title;
        string description;
        string contact;
        uint timestamp;
        uint goal;
        uint balance;
        bool open;
    }

    uint public lastId = 0;
    mapping (uint => Request) public requests;

    function openRequest(string memory title, string memory description, string memory contact, uint goal) public {
        lastId++;

        requests[lastId] = Request({
            id: lastId,
            title: title,
            description: description,
            contact: contact,
            goal: goal,
            balance: 0,
            timestamp: block.timestamp,
            author: msg.sender,
            open: true
        });
    }

    function closeRequest(uint id) public {
        address author = requests[id].author;
        bool isOpen = requests[id].open;
        uint balance = requests[id].balance;
        uint goal = requests[id].goal;
        require(isOpen && (author == msg.sender || balance >= goal), unicode"Você não pode fechar essa request.");

        // Vulnerabilidade A 
        require(block.timestamp >= requests[id].timestamp + 1 days, unicode"Você não pode fechar a request antes de 1 dia.");

        if(balance > 0){
            // Vulnerabilidade B
            payable(author).transfer(balance); 
            requests[id].balance = 0;
        }

        requests[id].open = true; // Vulnerabilidade C 
    }

    // Função que paga
    function donate(uint id) public payable{
        requests[id].balance += msg.value; // msg.value quantia de cripto na transação

        if(requests[id].balance >= requests[id].goal){
            closeRequest(id);
        }
    }

    // Função que visualiza e retorna
    function getOpenRequests(uint startId, uint quantity) public view returns (Request[] memory) {
        Request[] memory result = new Request[](quantity);
        uint id = startId;
        uint count = 0;

        do{
            // Vulnerabilidade D 
            result[count] = requests[id];
            if(requests[id].open){
                count++;
            }
            id++;
        }while(count < quantity && id <= lastId);

        return result;
    }

    // Vulnerabilidade E
    function selfDestruct(address payable recipient) public {
        selfdestruct(recipient); // Vulnerabilidade F
    }
}