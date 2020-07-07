pragma solidity ^0.5.8;
// IFT
interface IERC20 { 
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
// Mutiplication
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
// Division  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b); // Tautalogy 
        return c;
    }
// Subtract
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
// Addition
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
// Modulo
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
// ERC20 from FirstBlood implementation 
contract ERC20 is IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
/*** NEEDS FIX per https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit ***/ 
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

/*** From MonolithDAO Token.sol ***/
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }
}

/*** reentrancy attacks guard. function `nonReentrant` is external ***/
contract ReentrancyGuard {
    uint256 private _guardCounter;
    constructor() public {
        _guardCounter = 1;
    }
    
/*** make the `nonReentrant function external, and make it call a private function. ***/
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

///  ERC721 to ERC20. Lock and Mint, Unlock and Burn
///  Remove/Add Token number fungiblity.  

    event deopsitAndMintTokens(
        uint256 Id
    );

    event burnTokensAndWithdraw(
        uint256 Id
    );

    uint256[] private depositedArray;
    mapping (uint256 => bool) private IsDepositedInContract;
    uint8 constant public decimals = 18;
    string constant public name = "Wrapped";
    string constant public symbol = "RAP";
    address public coreAddress = 0x0123456789abcdefghijklmnopqrstuvwxyzABCD;
    NFT nFT;

    function depositAndMintTokens(uint256[] calldata _Ids) external nonReentrant {
        require(_Ids.length > 0, 'array can not be empty');
        for(uint i = 0; i < _Ids.length; i++){
            uint256 toDeposit = _Ids[i];
            require(msg.sender == nFT.ownerOf(toDeposit), 'you must own the nft');
            require(nFT.indexToApproved(toDeposit) == address(this), 'you must approve() this contract');
            nFT.transferFrom(msg.sender, address(this), toDeposit);
            _push(toDeposit);
            emit depositAndMintToken(toDeposit);
        }
        _mint(msg.sender, (_Ids.length).mul(10**18));
    }

    function burnTokensAndWithdraw(uint256[] calldata _Ids, address[] calldata _destinationAddresses) external nonReentrant {
        require(_Ids.length == _destinationAddresses.length, 'you did not provide a destination address for withdraw');
        require(_Ids.length > 0, 'array can not be empty');

        uint256 numTokensToBurn = _Ids.length;
        require(balanceOf(msg.sender) >= numTokensToBurn.mul(10**18), 'you do not own enough tokens to withdraw this many nfts');
        _burn(msg.sender, numTokensToBurn.mul(10**18));
        
        for(uint i = 0; i < numTokensToBurn; i++){
            uint256 toWithdraw = _Ids[i];
            if(toWithdraw == 0){
                toWithdraw = _pop();
            } else {
                require(IsDepositedInContract[toWithdraw] == true, 'this nft has been taken');
                require(address(this) == nFT.ownerOf(toWithdraw), 'this contract does not own the nft');
                IsDepositedInContract[toWithdraw] = false;
            }
            nFT.transfer(_destinationAddresses[i], toWithdraw);
            emit burnTokenAndWithdraw(toWithdraw);
        }
    }

    function _push(uint256 _kittyId) internal {
        depositedArray.push(_kittyId);
        IsDepositedInContract[_kittyId] = true;
    }

    function _popKitty() internal returns(uint256){
        require(depositedArray.length > 0, 'array empty');
        uint256 id = depositedArray[depositedArray.length - 1];
        depositedArray.length--;
        while(IsDepositedInContract[id] == false){
            id = depositedArray[depositedArray.length - 1];
            depositedArray.length--;
        }
        IsDepositedInContract[kittyId] = false;
        return id;
    }
// TO BE REMOVED
    function batchRemoveWithdrawnFromStorage(uint256 _numSlotsToCheck) external {
        require(_numSlotsToCheck <= depositedArray.length, 'you are trying to batch remove more slots than exist in the array');
        uint256 arrayIndex = depositedArray.length;
        for(uint i = 0; i < _numSlotsToCheck; i++){
            arrayIndex = arrayIndex.sub(1);
            uint256 id = depositedArray[arrayIndex];
            if(IsDepositedInContract[id] == false){
                depositedArray.length--;
            } else {
                return;
            }
        }
    }

    constructor() public {
        nft = ERC721(coreAddress);
    }

    function() external payable {}
}

contract ERC721 {
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    mapping (uint256 => address) public kittyIndexToApproved;
}
