// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../extensions/ERC721CollectionMetadataExtension.sol";
import "../extensions/ERC721PerTokenMetadataExtension.sol";
import "../extensions/ERC721OneOfOneMintExtension.sol";
import "../extensions/ERC721AutoIdMinterExtension.sol";
import "../extensions/ERC721OwnerMintExtension.sol";
import "../../../common/meta-transactions/UnorderedMetaTransactions.sol";

contract ERC721SimpleOneOfOneCollection is
    Ownable,
    ERC721,
    ERC721AutoIdMinterExtension,
    ERC721CollectionMetadataExtension,
    ERC721OwnerMintExtension,
    ERC721PerTokenMetadataExtension,
    ERC721OneOfOneMintExtension,
    UnorderedMetaTransactions
{
    struct Config {
        string name;
        string symbol;
        string contractURI;
        uint256 maxSupply;
    }

    constructor(Config memory config)
        ERC721(config.name, config.symbol)
        ERC721CollectionMetadataExtension(config.contractURI)
        ERC721PerTokenMetadataExtension()
        ERC721OneOfOneMintExtension()
        ERC721AutoIdMinterExtension(config.maxSupply)
        UnorderedMetaTransactions()
    {}

    // PUBLIC

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721, ERC721OneOfOneMintExtension, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721OneOfOneMintExtension.tokenURI(_tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721OneOfOneMintExtension, ERC721URIStorage)
    {
        return ERC721OneOfOneMintExtension._burn(tokenId);
    }

    function _msgSender()
        internal
        view
        virtual
        override(UnorderedMetaTransactions, Context)
        returns (address sender)
    {
        return UnorderedMetaTransactions._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(UnorderedMetaTransactions, Context)
        returns (bytes calldata)
    {
        return UnorderedMetaTransactions._msgData();
    }

    function getInfo()
        external
        view
        returns (
            uint256 _maxSupply,
            uint256 _totalSupply,
            uint256 _senderBalance
        )
    {
        uint256 balance = 0;

        if (_msgSender() != address(0)) {
            balance = this.balanceOf(_msgSender());
        }

        return (maxSupply, this.totalSupply(), balance);
    }
}
