//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./extensions/ERC721ASupply.sol";

// https://oneclickdapp.com/nato-germany

contract RandomTokenNFT is ERC721A, VRFConsumerBaseV2, Ownable, ERC721ASupply {
    VRFCoordinatorV2Interface COORDINATOR;
    using Strings for uint256;

    // Rinkeby coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash =
        0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 100000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    uint64 s_subscriptionId = 9781;
    uint256 s_requestId;
    uint256[] public s_randomWords;

    struct TokenInternalInfo {
        bool requested; // token reveal requested
        uint64 revealId;
        uint64 lastTransferTime;
        uint64 stateChangePeriod;
    }

    struct TokenReveal {
        bool requested; // token reveal requested
        uint64 revealId;
    }

    mapping(uint256 => uint256) public tokenIdMap;
    mapping(uint256 => uint256) public chainlinkTokenId;
    mapping(uint256 => TokenInternalInfo) public tokenInternalInfo;

    constructor()
        ERC721A("TEST", "TEST")
        VRFConsumerBaseV2(vrfCoordinator)
        ERC721ASupply(500, 500)
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    uint256 revealedTokens;

    function mint(uint256 _quantity) external {
        _baseMint(msg.sender, _quantity);
    }

    function _baseMint(address _to, uint256 _quantity) internal {
        if (_quantity > 1000) {
            revert Max1000TokenPerTransaction();
        }
        if (totalSupply() + _quantity > maxSupply) {
            revert ExceedsMaximumSupply();
        }
        if (totalSupply() + _quantity > supplyLimit) {
            revert ExceedsSupplyLimit();
        }
        _safeMint(_to, _quantity);
    }

    function requestReveal(uint256 _tokenId) external {
        if (ownerOf(_tokenId) != msg.sender) revert RequestRevealNotOwner();
        if (tokenInternalInfo[_tokenId].requested)
            revert RevealAlreadyRequested();

        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        tokenInternalInfo[_tokenId].requested = true;
        chainlinkTokenId[requestId] = _tokenId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 tokenId = chainlinkTokenId[requestId];
        if (
            tokenInternalInfo[tokenId].requested &&
            tokenInternalInfo[tokenId].revealId == 0
        ) {
            uint256 randomIndex = (randomWords[0] %
                (maxSupply - revealedTokens)) + revealedTokens;
            uint256 revealId = _tokenIdMap(randomIndex);
            uint256 currentId = _tokenIdMap(revealedTokens);

            tokenIdMap[randomIndex] = currentId;
            tokenInternalInfo[tokenId].revealId = uint64(revealId);
            revealedTokens++;
        }
    }

    function _tokenIdMap(uint256 _index) private view returns (uint256) {
        if (tokenIdMap[_index] == 0) {
            return _index + 1;
        } else {
            return tokenIdMap[_index];
        }
    }

    function tokenReveal(uint256 _tokenId)
        external
        view
        returns (TokenReveal memory)
    {
        if (!_exists(_tokenId)) revert TokenRevealQueryForNonexistentToken();

        return
            TokenReveal({
                requested: tokenInternalInfo[_tokenId].requested,
                revealId: tokenInternalInfo[_tokenId].revealId
            });
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked("ipfs://hash/", tokenId.toString()));
    }

    //// errors
    error RequestRevealNotOwner();
    error RevealAlreadyRequested();
    error Max1000TokenPerTransaction();
    error ExceedsMaximumSupply();
    error ExceedsSupplyLimit();
    error TokenRevealQueryForNonexistentToken();
}
