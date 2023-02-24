// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IShieldsAPI } from "shields-api/interfaces/IShieldsAPI.sol";
import { Owned } from "solmate/auth/Owned.sol";
import { ERC721 } from "solmate/tokens/ERC721.sol";
import { LibString } from "solmate/utils/LibString.sol";

import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { Base64 } from "@/contracts/utils/Base64.sol";

/// @title The Authorship Token ERC-721 token contract
/// @author fiveoutofnine
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
/// @notice ``Authorship Tokens'' are ERC-721 tokens that are required to add
/// puzzles to Curta. Each Authorship Token may be used like a ticket once.
/// After an Authorship Token has been used to add a puzzle, it can never be
/// used again to add another puzzle. As soon as a puzzle has been deployed and
/// added to Curta, anyone may attempt to solve it.
/// @dev Other than the initial distribution, the only way to obtain an
/// Authorship Token will be to be the first solver to any puzzle on Curta.
contract AuthorshipToken is ERC721, Owned {
    using LibString for uint256;

    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The shields API contract.
    /// @dev This is the mainnet address.
    IShieldsAPI constant shieldsAPI = IShieldsAPI(0x740CBbF0116a82F64e83E1AE68c92544870B0C0F);

    /// @notice Salt used to compute the seed in {AuthorshipToken-tokenURI}.
    bytes32 constant SALT = bytes32("Curta.AuthorshipToken");

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when there are no tokens available to claim.
    error NoTokensAvailable();

    /// @notice Emitted when `msg.sender` is not authorized.
    error Unauthorized();

    // -------------------------------------------------------------------------
    // Immutable Storage
    // -------------------------------------------------------------------------

    /// @notice The Curta / Flags contract.
    address public immutable curta;

    /// @notice The number of seconds until an additional token is made
    /// available for minting by the author.
    uint256 public immutable issueLength;

    /// @notice The timestamp of when the contract was deployed.
    uint256 public immutable deployTimestamp;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The number of tokens that have been claimed by the owner.
    uint256 public numClaimedByOwner;

    /// @notice The total supply of tokens.
    uint256 public totalSupply;

    /// @notice Mapping to keep track of which addresses have claimed from
    // the mint list.
    mapping(address => bool) public hasClaimed;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _curta The Curta / Flags contract.
    /// @param _issueLength The number of seconds until an additional token is
    /// made available for minting by the author.
    /// @param _authors The list of authors in the initial batch.
    constructor(address _curta, uint256 _issueLength, address[] memory _authors)
        ERC721("Authorship Token", "AUTH")
        Owned(msg.sender)
    {
        curta = _curta;
        issueLength = _issueLength;
        deployTimestamp = block.timestamp;

        // Mint tokens to the initial batch of authors.
        uint256 length = _authors.length;
        for (uint256 i; i < length;) {
            _mint(_authors[i], i + 1);
            unchecked {
                ++i;
            }
        }
        totalSupply = length;
    }

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @notice Mints a token to `_to`.
    /// @dev Only the Curta contract can call this function.
    /// @param _to The address to mint the token to.
    function curtaMint(address _to) external {
        // Revert if the sender is not the Curta contract.
        if (msg.sender != curta) revert Unauthorized();

        unchecked {
            uint256 tokenId = ++totalSupply;

            _mint(_to, tokenId);
        }
    }

    /// @notice Mints a token to `_to`.
    /// @dev Only the owner can call this function. The owner may claim a token
    /// every `issueLength` seconds.
    /// @param _to The address to mint the token to.
    function ownerMint(address _to) external onlyOwner {
        unchecked {
            uint256 numIssued = (block.timestamp - deployTimestamp) / issueLength;
            uint256 numMintable = numIssued - numClaimedByOwner++;

            // Revert if no tokens are available to mint.
            if (numMintable == 0) revert NoTokensAvailable();

            // Mint token
            uint256 tokenId = ++totalSupply;

            _mint(_to, tokenId);
        }
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param _tokenId The token ID.
    /// @return URI for the token.
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_ownerOf[_tokenId] != address(0), "NOT_MINTED");

        // Generate seed.
        uint256 seed = uint256(keccak256(abi.encodePacked(_tokenId, SALT)));

        // Bitpacked colors.
        uint256 colors = 0x6351CEFF00FFB300FF6B00B5000A007FFF78503C323232FE7FFF6C28A2FF007A;

        // Shuffle `colors` by performing 4 iterations of Fisher-Yates shuffle.
        // We do this to pick 4 unique colors from `colors`.
        unchecked {
            uint256 shift = 24 * (seed % 11);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ 0xFFFFFF))
                | ((colors & 0xFFFFFF) << shift) | ((colors >> shift) & 0xFFFFFF);
            seed >>= 4;

            shift = 24 * (seed % 10);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ (0xFFFFFF << 24)))
                | (((colors >> 24) & 0xFFFFFF) << shift) | (((colors >> shift) & 0xFFFFFF) << 24);
            seed >>= 4;

            shift = 24 * (seed % 9);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ (0xFFFFFF << 48)))
                | (((colors >> 48) & 0xFFFFFF) << shift) | (((colors >> shift) & 0xFFFFFF) << 48);
            seed >>= 4;

            shift = 24 * (seed & 7);
            colors = (colors & ((type(uint256).max ^ (0xFFFFFF << shift)) ^ (0xFFFFFF << 72)))
                | (((colors >> 72) & 0xFFFFFF) << shift) | (((colors >> shift) & 0xFFFFFF) << 72);
            seed >>= 3;
        }

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                abi.encodePacked(
                    '{"name":"Authorship Token #',
                    _tokenId.toString(),
                    '","description":"This token allows 1 puzzle to be added to Curta. Once it has '
                    'been used, it can never be used again.","image_data":"data:image/svg+xml;base6'
                    "4,",
                    Base64.encode(
                        abi.encodePacked(
                            '<svg width="750" height="750" xmlns="http://www.w3.org/2000/svg" fill='
                            '"none" viewBox="0 0 750 750"><path fill="#000" d="M0 0h750v750H0z"/><g'
                            ' transform="translate(215 65)"><svg width="320" height="620" viewBox="'
                            '0 0 320 620" fill="none" xmlns="http://www.w3.org/2000/svg"><style>rec'
                            't.a{filter:url(#c)drop-shadow(0 0 32px #007fff);fill:#fff;width:64px}r'
                            'ect.b{filter:drop-shadow(0 0 8px #007fff);fill:#000;width:48px}rect.c{'
                            'height:208px}rect.d{height:96px}rect.e{height:64px}rect.f{height:192px'
                            '}rect.g{height:80px}rect.h{height:48px}rect.i{width:320px;height:620px'
                            '}circle.j{cx:160px;r:20px}@font-face{font-family:&quot;A&quot;;src:url'
                            '(data:font/ttf;charset=utf-8;base64,AAEAAAAPAIAAAwBwR1NVQjLBMmgAACFIAA'
                            'AA2E9TLzI5l3XkAAARlAAAAGBjbWFwAGIAcgAAEfQAAAA8Y3Z0IBTvGz8AAB7IAAAAimZw'
                            'Z20/rh6lAAASMAAAC+JnYXNwAAAAEAAAIUAAAAAIZ2x5ZimvKtEAAAD8AAAPkmhlYWQKQj'
                            'EwAAAQ9AAAADZoaGVhBtcA8QAAEXAAAAAkaG10eAv/CTsAABEsAAAAQmxvY2FPXEssAAAQ'
                            'sAAAAEJtYXhwAX4M/AAAEJAAAAAgbmFtZSNCPIoAAB9UAAABzHBvc3T/uAAzAAAhIAAAAC'
                            'BwcmVwNvA2NQAAHhQAAACxAAMAPP/yAigCygANAB8AKwAyQC8ABAAFAgQFYwADAwBbAAAA'
                            'H0sGAQICAVsAAQEgAUwPDiooJCIYFg4fDx8lIgcHFisTNDYzMhYVFRQGIyImNRcyNjU1NC'
                            '4CIyIOAhUVFBYTNDYzMhYVFAYjIiY8gnR0goJ0dIL2UVEUKT0oKTwpFFERJhoaJiYaGiYB'
                            'rIiWloicjJKSjNJxZ5AwTzkgIDlPMJBncQEgGiYmGhomJgAAAQA7AAACJwK8AAwAMEAtAA'
                            'EAAwABA3AAAAACWQACAhdLBgUCAwMEWQAEBBgETAAAAAwADBEREhERBwcZKyURIwMjNRMz'
                            'ETMVITUBDQxzU4Ojxv4gTgJJ/vkGASb9kk5OAAABAEAAAAImAsoAKQAuQCsAAgEEAQIEcA'
                            'ABAQNbAAMDH0sFAQQEAFkAAAAYAEwAAAApACklEy4RBgcYKyUVITU0PgI3NjY1NTQuAiMi'
                            'BhUVIzU0PgIzMh4CFRUUBgcGBhUVAiD+JiA7VDVZTxImOylNVVQgPlw8PVo8HWRuYFpOTn'
                            'gwRzMiDBRKNgYbNCoZXk4sMjBYRCglPU0oElBxGBVFQh4AAAEAP//yAisCvAArAEFAPggH'
                            'AgEEAgABSgAEBgUGBAVwAAIHAQYEAgZhAAAAAVkAAQEXSwAFBQNbAAMDIANMAAAAKwAqJR'
                            'UpIxETCAcaKxM1NzUhNSEVBxUzMh4CFRUUDgIjIi4CNTUzFRQeAjMyPgI1NTQmI+3k/nQB'
                            '1OQoKEo5IyRAVzM7XkIjVBktPiQhOSoYUDwBXHSSDE6AkgwaMkkwEi1OOSEkP1UwNjAmOy'
                            'kWFic1HgY/RwACADEAAAI1ArwACgAPAC5AKwsKAgEGAUoFAQEEAQIDAQJhAAYGAFkAAAAX'
                            'SwADAxgDTBETERERERAHBxsrATMRMxUjFSM1ITUXFTMRIwEmo2xsVP68SPwMArz+Fk6EhH'
                            'QaDAHGAAABAEL/8gI0ArwAMQB9S7AXUFhAMAAFCAYIBQZwAAIJAQgFAghhAAEBAFkAAAAX'
                            'SwAHBwNbAAMDGksABgYEWwAEBCAETBtALgAFCAYIBQZwAAMABwIDB2MAAgkBCAUCCGEAAQ'
                            'EAWQAAABdLAAYGBFsABAQgBExZQBEAAAAxADEpIxUpJBEREQoHHCsTESEVIRUzPgMzMh4C'
                            'FRUUDgIjIi4CNTUzFRQWMzI+AjU1NC4CIyIOAgdOAbb+nAwKICs2ITBROiEgPlw8PV5AIV'
                            'RdSyg9KRQVJTUfFSMaEQMBSgFyTvoUJRwRIDpSMhIyWUUoJEBXMxwWU1MdMUEjBh82KBcM'
                            'ExgLAAIAP//yAiUCygAoAD4ASEBFCAEFAAIABQJwAAEHBgcBBnAAAgAHAQIHYwAAAARbAA'
                            'QEH0sJAQYGA1sAAwMgA0wqKQAANTMpPio+ACgAKCkpIhUiCgcZKwE0JiMiDgIVFTM2NjMy'
                            'HgIVFRQOAiMiLgI1NTQ+AjMyHgIVAzI+AjU1NC4CIyIOAhUVFB4CAcVQRyI5KRcMGFk3MF'
                            'I7ISVBWTQ0WUElJkJXMjJWPiPnJDsqFhgqOyIiOisYFio7AfBBTxgtPiVoLDIfPFU2DDRW'
                            'PiIiPVUz/zdaPyIeOVEy/kwXKjojDCM6KhcYKjggEyE5KhcAAQBIAAACHAK8ABEAIEAdDw'
                            'ICAQIBSgACAgBZAAAAF0sAAQEYAUwYFhADBxcrEyEVAQYGFRUjNTQ+AjcBNSFIAdT+2RUW'
                            'UgcPFxABH/50Arx6/kIgLhgeJBIgISUYAa4MAAADAD//8gIlAsoALwA/AE0AR0BEJCMMCw'
                            'QDBAFKCAEEAAMCBANjAAUFAVsAAQEfSwcBAgIAWwYBAAAgAExBQDEwAQBIRkBNQU05NjA/'
                            'MT4ZFgAvAS4JBxQrBSIuAjU1ND4CNzUuAzU1ND4CMzMyHgIVFRQOAgcVHgMVFRQOAiMnMj'
                            'Y1NTQmIyMiBhUVFBYzEzI2NTU0JiMiBhUVFBYBKTVWPiEWJC8ZFygfEiA7UTIGMVI7IBIf'
                            'KRYZLyQWIT5WNQNEVVdFBkVXVUQGP05NQEBNTg4dM0UpDCQ4KhwHDAccJjEdDChDMBsbME'
                            'MoDB0xJhwHDAccKjgkDClFMx1MRjgGPkREPgY4RgFUQjIGMz8/MwYyQgACAD//8gIlAsoA'
                            'KAA+AEhARQABBgcGAQdwCAEFAgACBQBwAAcAAgUHAmMJAQYGA1sAAwMfSwAAAARbAAQEIA'
                            'RMKikAADUzKT4qPgAoACgpKSIVIgoHGSs3FBYzMj4CNTUjBgYjIi4CNTU0PgIzMh4CFRUU'
                            'DgIjIi4CNRMiDgIVFRQeAjMyPgI1NTQuAp9QRyI5KRcMF1Y5MVI8ISRBWTU1WUEkJUFYMz'
                            'NWPiLnJDsqFhgqOiMiOisYFio7zEFPGC09JmgsMh47VDYMNFc/IyM+VjP8OFk/Ih45UTIB'
                            'tBgsOyIMIzkpFhcoOCATITorGAACAEYAZgIeAlYAGwAfAH1LsBlQWEAlDwsCAwwCAgABAw'
                            'BhCAEGEA0CAQYBXQ4KAgQEBVkJBwIFBRoETBtALAgBBgUBBlUJBwIFDgoCBAMFBGEPCwID'
                            'DAICAAEDAGEIAQYGAVkQDQIBBgFNWUAeAAAfHh0cABsAGxoZGBcWFRQTEREREREREREREQ'
                            'cdKyU1IxUjNSM1MzUjNTM1MxUzNTMVMxUjFTMVIxUDIxUzAWhsSG5ubm5IbEhubm5uSGxs'
                            'Znp6ekhsSHp6enpIbEh6AS5sAAADAMoBlgGaAsIADQAbACcAMkAvAAQABQIEBWMAAwMBWw'
                            'ABAT5LBgECAgBbAAAAPwBMDw4mJCAeFhQOGw8bJSIHCRYrARQGIyImNTU0NjMyFhUHMjY1'
                            'NTQmIyIGFRUUFic0NjMyFhUUBiMiJgGaNDMyNzgxMzRnFxoaFxccHAoTDQ4REQ4NEwH/Lj'
                            's7LlouOzsukx0WZhYdHRZmFh1mDhISDg4REQAAAQDRAZwBogK8AAsAWUuwDlBYQB4AAQAD'
                            'AAFoAAAAAlkAAgI5SwYFAgMDBFkABAQ6BEwbQB8AAQADAAEDcAAAAAJZAAICOUsGBQIDAw'
                            'RZAAQEOgRMWUAOAAAACwALEREREREHCRkrATUjByM3MxUzFSM1ASUJFjUgakfLAczSXXvw'
                            'MDAAAQDMAZwBmALCACEALkArAAIBBAECBHAAAQEDWwADAz5LBQEEBABZAAAAOgBMAAAAIQ'
                            'AgIxMpEQYJGCsBFSM1NDY3NjY1NCYjIgYVFSM1NDYzMh4CFRQGBwYGFRUBlcMwMCEPFhgX'
                            'GzY3MxglGA0kMCQYAcwwNiotCwgcDhEbHBoSEio8DxkhESQ0CggYFAYAAQDMAZYBmAK8AB'
                            '8AsLcIBwEDAgABSkuwClBYQCoAAgAGBQJoBwEGBAAGZgAEBQAEBW4AAAABWQABATlLAAUF'
                            'A1wAAwM/A0wbS7AMUFhAKwACAAYAAgZwBwEGBAAGZgAEBQAEBW4AAAABWQABATlLAAUFA1'
                            'wAAwM/A0wbQCwAAgAGAAIGcAcBBgQABgRuAAQFAAQFbgAAAAFZAAEBOUsABQUDXAADAz8D'
                            'TFlZQA8AAAAfAB4jEyQUESIICRorATU3NSM1MxUHFTMyFhUUBiMiJjU1MxUUFjMyNjU0Ji'
                            'MBFFKRu1IGJDA3LTA4NhkXFxkdEQIeTBwGMFQcBiknKzU5JxAOFxsYFBgUAAACAMoBnAGq'
                            'ArwACgAPAC5AKw4KAgEAAUoNAQEBSQABAgIBVQQBAgIAWQAAADlLAAMDOgNMERERERAFCR'
                            'krATMVMxUjFSM1IzUXFTM1IwEfYygoNoIwUgYCvLowNjZCDAacAAEAzgGWAaICvAAgAEJA'
                            'PwUBBQIVEwIEBgJKBwEGBQQFBmgAAgAFBgIFYwABAQBZAAAAOUsABAQDWwADAz8DTAAAAC'
                            'AAICQnJCMREQgJGisTNTMVIxUzNjMyFhUUBiMiLgI1NTMUMzI2NTQmIyIGB9S8hgYRLSYu'
                            'NDYdKBkMNjYYGhcPDQ8CAhuhMFAjMSwvPRAaIRIGMx8dFxYMCAAAAgDOAZYBlgLCABsAJw'
                            'BFQEIHAQUBAUoHAQQAAQAEAXAAAQgBBQYBBWMAAAADWwADAz5LAAYGAlsAAgI/AkwdHAAA'
                            'IyEcJx0nABsAGyUkJiIJCRgrATQmIyIGFRUzNjYzMhYVFAYjIiY1NTQ2MzIWFQciBhUUFj'
                            'MyNjU0JgFbFhYVFgYFGRknLjkrLTc3Kyw1XxUZGRUVGRkCaBIYGhYmDBI3KS81NCxsLTMw'
                            'Kj4bFxcbGxcXGwABANwBnAGcArwADwAfQBwCAQECAUoAAgIAWQAAADlLAAEBOgFMJRYQAw'
                            'kXKxMzFQcGBhUVIzU0Njc3NSPcwGIICDsNDGqWArxYlQsRCwwPEBkSngYAAAMAzgGWAZYC'
                            'wgAdACkANQBFQEIVCAIDBAFKCAEEAAMCBANjAAUFAVsAAQE+SwcBAgIAWwYBAAA/AEwrKh'
                            '8eAQAxLyo1KzUlIx4pHykQDgAdAR0JCRQrASIuAjU0Njc1JiY1NDYzMhYVFAYHFRYWFRQO'
                            'AicyNjU0JiMiBhUUFjcyNjU0JiMiBhUUFgEyFCQbESEUER41KSk1HhEUIREbJRMUGhoUFB'
                            'oaFBMbGxMTGxsBlgoVHxYeIQUGBR8eIykpIx4fBQYFIR4WHxUKMBYUFBYWFBQWhBISEhIS'
                            'EhISAAIAzgGWAZYCwgAbACcARUBCBwEBBQFKBwEEAQABBABwCAEFAAEEBQFjAAYGAlsAAg'
                            'I+SwAAAANbAAMDPwNMHRwAACMhHCcdJwAbABslJCYiCQkYKwEUFjMyNjU1IwYGIyImNTQ2'
                            'MzIWFRUUBiMiJjU3MjY1NCYjIgYVFBYBCRYWFRYGBRkZJy45Ky03NyssNV8VGRkVFRkZAf'
                            'ASGBoWJgwSNykvNTQsbC0zMCo+GxcXGxsXFxv//wDK/zMBmgBfAwcADAAA/Z0ACbEAA7j9'
                            'nbAzKwD//wDR/zkBogBZAwcADQAA/Z0ACbEAAbj9nbAzKwD//wDM/zkBmABfAwcADgAA/Z'
                            '0ACbEAAbj9nbAzKwD//wDM/zMBmABZAwcADwAA/Z0ACbEAAbj9nbAzKwD//wDK/zkBqgBZ'
                            'AwcAEAAA/Z0ACbEAArj9nbAzKwD//wDO/zMBogBZAwcAEQAA/Z0ACbEAAbj9nbAzKwD//w'
                            'DO/zMBlgBfAwcAEgAA/Z0ACbEAArj9nbAzKwD//wDc/zkBnABZAwcAEwAA/Z0ACbEAAbj9'
                            'nbAzKwD//wDO/zMBlgBfAwcAFAAA/Z0ACbEAA7j9nbAzKwD//wDO/zMBlgBfAwcAFQAA/Z'
                            '0ACbEAArj9nbAzKwAAAAABAAAAIABoAAYAcQAFAAIALgA+AHcAAACqC+IAAwABAAAAAABY'
                            'AIkA2wE3AWoB7AJlApYDIAOYBAEEVASWBN4FYwWUBeMGPgZpBtgHMwdCB1EHYAdvB34HjQ'
                            'ecB6sHugfJAAAAAQAAAAEAQla8DslfDzz1ABsD6AAAAADTbNzWAAAAANUyECUABP7LAnAE'
                            'QgAAAAkAAgAAAAAAAAJkAAAAPAA7AEAAPwAxAEIAPwBIAD8APwBGAMoA0QDMAMwAygDOAM'
                            '4A3ADOAM4AygDRAMwAzADKAM4AzgDcAM4AzgAAAAEAAARg/pcAAAJkAAT/9AJwAAEAAAAA'
                            'AAAAAAAAAAAAAAABAAQCZAGQAAUAAAKKAlgAAABLAooCWAAAAV4AMgEpAAACAAUJBAAAAg'
                            'AEAAAAAQAAAAAAAAAAAAAAAENGICAAwAAjADkEYP6XAAAEYAFpIAABkwAAAAAB8AK8AAAA'
                            'IAAEAAAAAgAAAAMAAAAUAAMAAQAAABQABAAoAAAABgAEAAEAAgAjADn//wAAACMAMP///+'
                            'j/0QABAAAAAAAAsAAsILAAVVhFWSAgS7gADlFLsAZTWliwNBuwKFlgZiCKVViwAiVhuQgA'
                            'CABjYyNiGyEhsABZsABDI0SyAAEAQ2BCLbABLLAgYGYtsAIsIGQgsMBQsAQmWrIoAQpDRW'
                            'NFsAZFWCGwAyVZUltYISMhG4pYILBQUFghsEBZGyCwOFBYIbA4WVkgsQEKQ0VjRWFksChQ'
                            'WCGxAQpDRWNFILAwUFghsDBZGyCwwFBYIGYgiophILAKUFhgGyCwIFBYIbAKYBsgsDZQWC'
                            'GwNmAbYFlZWRuwAStZWSOwAFBYZVlZLbADLCBFILAEJWFkILAFQ1BYsAUjQrAGI0IbISFZ'
                            'sAFgLbAELCMhIyEgZLEFYkIgsAYjQrAGRVgbsQEKQ0VjsQEKQ7AEYEVjsAMqISCwBkMgii'
                            'CKsAErsTAFJbAEJlFYYFAbYVJZWCNZIVkgsEBTWLABKxshsEBZI7AAUFhlWS2wBSywB0Mr'
                            'sgACAENgQi2wBiywByNCIyCwACNCYbACYmawAWOwAWCwBSotsAcsICBFILALQ2O4BABiIL'
                            'AAUFiwQGBZZrABY2BEsAFgLbAILLIHCwBDRUIqIbIAAQBDYEItsAkssABDI0SyAAEAQ2BC'
                            'LbAKLCAgRSCwASsjsABDsAQlYCBFiiNhIGQgsCBQWCGwABuwMFBYsCAbsEBZWSOwAFBYZV'
                            'mwAyUjYUREsAFgLbALLCAgRSCwASsjsABDsAQlYCBFiiNhIGSwJFBYsAAbsEBZI7AAUFhl'
                            'WbADJSNhRESwAWAtsAwsILAAI0KyCwoDRVghGyMhWSohLbANLLECAkWwZGFELbAOLLABYC'
                            'AgsAxDSrAAUFggsAwjQlmwDUNKsABSWCCwDSNCWS2wDywgsBBiZrABYyC4BABjiiNhsA5D'
                            'YCCKYCCwDiNCIy2wECxLVFixBGREWSSwDWUjeC2wESxLUVhLU1ixBGREWRshWSSwE2UjeC'
                            '2wEiyxAA9DVVixDw9DsAFhQrAPK1mwAEOwAiVCsQwCJUKxDQIlQrABFiMgsAMlUFixAQBD'
                            'YLAEJUKKiiCKI2GwDiohI7ABYSCKI2GwDiohG7EBAENgsAIlQrACJWGwDiohWbAMQ0ewDU'
                            'NHYLACYiCwAFBYsEBgWWawAWMgsAtDY7gEAGIgsABQWLBAYFlmsAFjYLEAABMjRLABQ7AA'
                            'PrIBAQFDYEItsBMsALEAAkVUWLAPI0IgRbALI0KwCiOwBGBCIGCwAWG1EBABAA4AQkKKYL'
                            'ESBiuwdSsbIlktsBQssQATKy2wFSyxARMrLbAWLLECEystsBcssQMTKy2wGCyxBBMrLbAZ'
                            'LLEFEystsBossQYTKy2wGyyxBxMrLbAcLLEIEystsB0ssQkTKy2wKSwjILAQYmawAWOwBm'
                            'BLVFgjIC6wAV0bISFZLbAqLCMgsBBiZrABY7AWYEtUWCMgLrABcRshIVktsCssIyCwEGJm'
                            'sAFjsCZgS1RYIyAusAFyGyEhWS2wHiwAsA0rsQACRVRYsA8jQiBFsAsjQrAKI7AEYEIgYL'
                            'ABYbUQEAEADgBCQopgsRIGK7B1KxsiWS2wHyyxAB4rLbAgLLEBHistsCEssQIeKy2wIiyx'
                            'Ax4rLbAjLLEEHistsCQssQUeKy2wJSyxBh4rLbAmLLEHHistsCcssQgeKy2wKCyxCR4rLb'
                            'AsLCA8sAFgLbAtLCBgsBBgIEMjsAFgQ7ACJWGwAWCwLCohLbAuLLAtK7AtKi2wLywgIEcg'
                            'ILALQ2O4BABiILAAUFiwQGBZZrABY2AjYTgjIIpVWCBHICCwC0NjuAQAYiCwAFBYsEBgWW'
                            'awAWNgI2E4GyFZLbAwLACxAAJFVFiwARawLyqxBQEVRVgwWRsiWS2wMSwAsA0rsQACRVRY'
                            'sAEWsC8qsQUBFUVYMFkbIlktsDIsIDWwAWAtsDMsALABRWO4BABiILAAUFiwQGBZZrABY7'
                            'ABK7ALQ2O4BABiILAAUFiwQGBZZrABY7ABK7AAFrQAAAAAAEQ+IzixMgEVKi2wNCwgPCBH'
                            'ILALQ2O4BABiILAAUFiwQGBZZrABY2CwAENhOC2wNSwuFzwtsDYsIDwgRyCwC0NjuAQAYi'
                            'CwAFBYsEBgWWawAWNgsABDYbABQ2M4LbA3LLECABYlIC4gR7AAI0KwAiVJiopHI0cjYSBY'
                            'YhshWbABI0KyNgEBFRQqLbA4LLAAFrAEJbAEJUcjRyNhsAlDK2WKLiMgIDyKOC2wOSywAB'
                            'awBCWwBCUgLkcjRyNhILAEI0KwCUMrILBgUFggsEBRWLMCIAMgG7MCJgMaWUJCIyCwCEMg'
                            'iiNHI0cjYSNGYLAEQ7ACYiCwAFBYsEBgWWawAWNgILABKyCKimEgsAJDYGQjsANDYWRQWL'
                            'ACQ2EbsANDYFmwAyWwAmIgsABQWLBAYFlmsAFjYSMgILAEJiNGYTgbI7AIQ0awAiWwCENH'
                            'I0cjYWAgsARDsAJiILAAUFiwQGBZZrABY2AjILABKyOwBENgsAErsAUlYbAFJbACYiCwAF'
                            'BYsEBgWWawAWOwBCZhILAEJWBkI7ADJWBkUFghGyMhWSMgILAEJiNGYThZLbA6LLAAFiAg'
                            'ILAFJiAuRyNHI2EjPDgtsDsssAAWILAII0IgICBGI0ewASsjYTgtsDwssAAWsAMlsAIlRy'
                            'NHI2GwAFRYLiA8IyEbsAIlsAIlRyNHI2EgsAUlsAQlRyNHI2GwBiWwBSVJsAIlYbkIAAgA'
                            'Y2MjIFhiGyFZY7gEAGIgsABQWLBAYFlmsAFjYCMuIyAgPIo4IyFZLbA9LLAAFiCwCEMgLk'
                            'cjRyNhIGCwIGBmsAJiILAAUFiwQGBZZrABYyMgIDyKOC2wPiwjIC5GsAIlRlJYIDxZLrEu'
                            'ARQrLbA/LCMgLkawAiVGUFggPFkusS4BFCstsEAsIyAuRrACJUZSWCA8WSMgLkawAiVGUF'
                            'ggPFkusS4BFCstsEEssDgrIyAuRrACJUZSWCA8WS6xLgEUKy2wQiywOSuKICA8sAQjQoo4'
                            'IyAuRrACJUZSWCA8WS6xLgEUK7AEQy6wListsEMssAAWsAQlsAQmIC5HI0cjYbAJQysjID'
                            'wgLiM4sS4BFCstsEQssQgEJUKwABawBCWwBCUgLkcjRyNhILAEI0KwCUMrILBgUFggsEBR'
                            'WLMCIAMgG7MCJgMaWUJCIyBHsARDsAJiILAAUFiwQGBZZrABY2AgsAErIIqKYSCwAkNgZC'
                            'OwA0NhZFBYsAJDYRuwA0NgWbADJbACYiCwAFBYsEBgWWawAWNhsAIlRmE4IyA8IzgbISAg'
                            'RiNHsAErI2E4IVmxLgEUKy2wRSywOCsusS4BFCstsEYssDkrISMgIDywBCNCIzixLgEUK7'
                            'AEQy6wListsEcssAAVIEewACNCsgABARUUEy6wNCotsEgssAAVIEewACNCsgABARUUEy6w'
                            'NCotsEkssQABFBOwNSotsEossDcqLbBLLLAAFkUjIC4gRoojYTixLgEUKy2wTCywCCNCsE'
                            'srLbBNLLIAAEQrLbBOLLIAAUQrLbBPLLIBAEQrLbBQLLIBAUQrLbBRLLIAAEUrLbBSLLIA'
                            'AUUrLbBTLLIBAEUrLbBULLIBAUUrLbBVLLIAAEErLbBWLLIAAUErLbBXLLIBAEErLbBYLL'
                            'IBAUErLbBZLLIAAEMrLbBaLLIAAUMrLbBbLLIBAEMrLbBcLLIBAUMrLbBdLLIAAEYrLbBe'
                            'LLIAAUYrLbBfLLIBAEYrLbBgLLIBAUYrLbBhLLIAAEIrLbBiLLIAAUIrLbBjLLIBAEIrLb'
                            'BkLLIBAUIrLbBlLLA6Ky6xLgEUKy2wZiywOiuwPistsGcssDorsD8rLbBoLLAAFrA6K7BA'
                            'Ky2waSywOysusS4BFCstsGossDsrsD4rLbBrLLA7K7A/Ky2wbCywOyuwQCstsG0ssDwrLr'
                            'EuARQrLbBuLLA8K7A+Ky2wbyywPCuwPystsHAssDwrsEArLbBxLLA9Ky6xLgEUKy2wciyw'
                            'PSuwPistsHMssD0rsD8rLbB0LLA9K7BAKy2wdSyzCQQCA0VYIRsjIVlCK7AIZbADJFB4sQ'
                            'UBFUVYMFktAAAAS7gAyFJYsQEBjlmwAbkIAAgAY3CxAAdCtQAAACIEACqxAAdCQApEATYG'
                            'KQUVCAQIKrEAB0JACkUAPgMwAh8GBAgqsQALQr0RQA3ACoAFgAAEAAkqsQAPQr0AAACAAI'
                            'AAQAAEAAkqsQMARLEkAYhRWLBAiFixA2REsSYBiFFYugiAAAEEQIhjVFixAwBEWVlZWUAK'
                            'RQA5BSwEFwgEDCq4Af+FsASNsQIARLMFZAYAREQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
                            'AAAAAAAAAAAAAAAAAAAAAAAABQAFAASgBKArwAAAK8AfAAAP84A7j/HgLK//ICygH+//L/'
                            'OAO4/x4AOQA5ADAAMAA/AFn/OQO4/x4AX/8zA7j/HgA5ADkAMAAwAD8CvAGcAz4DuP8eAs'
                            'IBlgM+A7j/HgAYABgAAAAAAAcAWgADAAEECQAAAF4AAAADAAEECQABABQAXgADAAEECQAC'
                            'AA4AcgADAAEECQADADgAgAADAAEECQAEACQAuAADAAEECQAFAHQA3AADAAEECQAGACIBUA'
                            'BDAG8AcAB5AHIAaQBnAGgAdAAgADIAMAAxADYAIABHAG8AbwBnAGwAZQAgAEkAbgBjAC4A'
                            'IABBAGwAbAAgAFIAaQBnAGgAdABzACAAUgBlAHMAZQByAHYAZQBkAC4AUwBwAGEAYwBlAC'
                            'AATQBvAG4AbwBSAGUAZwB1AGwAYQByADEALgAwADAAMQA7AFUASwBXAE4AOwBTAHAAYQBj'
                            'AGUATQBvAG4AbwAtAFIAZQBnAHUAbABhAHIAUwBwAGEAYwBlACAATQBvAG4AbwAgAFIAZQ'
                            'BnAHUAbABhAHIAVgBlAHIAcwBpAG8AbgAgADEALgAwADAAMQA7AFAAUwAgADEALgAwADAA'
                            'MwA7AGgAbwB0AGMAbwBuAHYAIAAxAC4AMAAuADgAMQA7AG0AYQBrAGUAbwB0AGYALgBsAG'
                            'kAYgAyAC4ANQAuADYAMwA0ADAANgBTAHAAYQBjAGUATQBvAG4AbwAtAFIAZQBnAHUAbABh'
                            'AHIAAwAAAAAAAP+1ADIAAAABAAAAAAAAAAAAAAAAAAAAAAABAAH//wAPAAEAAAAKADgAgA'
                            'ACREZMVAAObGF0bgAeAAQAAAAA//8AAwAAAAIABAAEAAAAAP//AAMAAQADAAUABmRub20A'
                            'JmRub20ALGZyYWMANGZyYWMANG51bXIAOm51bXIAQAAAAAEAAwAAAAIAAwAEAAAAAQAAAA'
                            'AAAQABAAAAAgABAAIABgAOADIAMgBAAEAAQAAGAAAAAQAIAAMAAQASAAEAOAAAAAEAAAAF'
                            'AAIAAQAWAB8AAAABAAAAAQAIAAEAFAALAAEAAAABAAgAAQAGABUAAgABAAEACgAA)}</st'
                            'yle><defs><radialGradient id="b"><stop style="stop-color:#007FFF;stop-'
                            'opacity:1"/><stop offset="100%" style="stop-opacity:0"/></radialGradie'
                            'nt><filter id="c"><feGaussianBlur stdDeviation="8" in="SourceGraphic" '
                            'result="offset-blur"/><feComposite operator="out" in="SourceGraphic" i'
                            'n2="offset-blur" result="inverse"/><feFlood flood-color="#007FFF" floo'
                            'd-opacity=".95" result="color"/><feComposite operator="in" in="color" '
                            'in2="inverse" result="shadow"/><feComposite in="shadow" in2="SourceGra'
                            'phic"/><feComposite operator="atop" in="shadow" in2="SourceGraphic"/><'
                            '/filter><mask id="a"><rect class="i" fill="#FFF" rx="20"/><circle clas'
                            's="j" fill="#000"/><circle class="j" cy="620" fill="#000"/></mask></de'
                            'fs><rect class="i" fill="#0D1017" mask="url(#a)" rx="20"/><circle fill'
                            '="url(#b)" cx="160" cy="320" r="200"/><circle fill="#0D1017" class="j"'
                            ' cy="60" stroke="#27303D"/><g transform="translate(144 45) scale(.0625'
                            ')"><rect width="512" height="512" fill="#0D1017" rx="256"/><rect class'
                            '="a c" x="128" y="112" rx="32"/><rect class="b f" x="136" y="120" rx="'
                            '24"/><rect class="a e" x="128" y="336" rx="32"/><rect class="b h" x="1'
                            '36" y="344" rx="24"/><rect class="a d" x="224" y="112" rx="32"/><rect '
                            'class="b g" x="232" y="120" rx="24"/><rect class="a e" x="224" y="224"'
                            ' rx="32"/><rect class="b h" x="232" y="232" rx="24"/><rect class="a d"'
                            ' x="224" y="304" rx="32"/><rect class="b g" x="232" y="312" rx="24"/><'
                            'rect class="a c" x="320" y="192" rx="32"/><rect class="b f" x="328" y='
                            '"200" rx="24"/><rect class="a e" x="320" y="112" rx="32"/><rect class='
                            '"b h" x="328" y="120" rx="24"/></g><path d="M123.814 103.856c-.373 0-.'
                            '718-.063-1.037-.191a2.829 2.829 0 0 1-.878-.606 2.828 2.828 0 0 1-.606'
                            '-.878 2.767 2.767 0 0 1-.193-1.037v-.336c0-.372.064-.723.192-1.053.138'
                            '-.319.34-.611.606-.877a2.59 2.59 0 0 1 .878-.59 2.58 2.58 0 0 1 1.038-'
                            '.208h4.26c.245 0 .48.032.703.096.212.053.425.143.638.27.223.118.415.25'
                            '6.574.416.16.16.304.345.431.558.043.064.07.133.08.208a.301.301 0 0 1-.'
                            '016.095.346.346 0 0 1-.175.256.42.42 0 0 1-.32.032.333.333 0 0 1-.239-'
                            '.192 3.016 3.016 0 0 0-.303-.399 2.614 2.614 0 0 0-.415-.303 1.935 1.9'
                            '35 0 0 0-.463-.191 1.536 1.536 0 0 0-.495-.048c-.712 0-1.42-.006-2.122'
                            '-.016-.713 0-1.425.005-2.138.016-.266 0-.51.042-.734.127-.234.096-.442'
                            '.24-.623.431a1.988 1.988 0 0 0-.43.623 1.961 1.961 0 0 0-.144.75v.335a'
                            '1.844 1.844 0 0 0 .574 1.356 1.844 1.844 0 0 0 1.356.574h4.261c.17 0 .'
                            '33-.015.48-.047a2.02 2.02 0 0 0 .446-.192c.149-.074.282-.165.399-.271.'
                            '106-.107.207-.229.303-.367a.438.438 0 0 1 .255-.144c.096-.01.187.01.27'
                            '2.064a.35.35 0 0 1 .16.24.306.306 0 0 1-.033.27 2.653 2.653 0 0 1-.43.'
                            '527c-.16.139-.346.266-.559.383-.213.117-.42.197-.622.24-.213.053-.436.'
                            '08-.67.08h-4.262Zm17.553 0c-.713 0-1.324-.266-1.835-.797a2.69 2.69 0 0'
                            ' 1-.766-1.931v-2.665c0-.117.037-.213.112-.287a.37.37 0 0 1 .27-.112c.1'
                            '18 0 .214.037.288.112a.39.39 0 0 1 .112.287v2.664c0 .533.18.99.542 1.3'
                            '73a1.71 1.71 0 0 0 1.293.559h3.878c.51 0 .941-.187 1.292-.559a1.93 1.9'
                            '3 0 0 0 .543-1.372v-2.665a.39.39 0 0 1 .111-.287.389.389 0 0 1 .288-.1'
                            '12.37.37 0 0 1 .271.112.39.39 0 0 1 .112.287v2.664c0 .756-.256 1.4-.76'
                            '6 1.932-.51.531-1.128.797-1.851.797h-3.894Zm23.824-.718a.456.456 0 0 1'
                            ' .16.192c.01.042.016.09.016.143a.47.47 0 0 1-.016.112.355.355 0 0 1-.1'
                            '43.208.423.423 0 0 1-.24.063h-.048a.141.141 0 0 1-.064-.016c-.02 0-.03'
                            '7-.005-.047-.016a104.86 104.86 0 0 1-1.18-.83c-.374-.265-.746-.531-1.1'
                            '18-.797-.011 0-.016-.006-.016-.016-.01 0-.016-.005-.016-.016-.01 0-.01'
                            '6-.005-.016-.016h-5.553v1.324a.39.39 0 0 1-.112.288.425.425 0 0 1-.287'
                            '.111.37.37 0 0 1-.272-.111.389.389 0 0 1-.111-.288v-4.946c0-.054.005-.'
                            '107.016-.16a.502.502 0 0 1 .095-.128.374.374 0 0 1 .128-.08.316.316 0 '
                            '0 1 .144-.031h6.893c.256 0 .49.048.702.143.224.085.42.218.59.4.182.18.'
                            '32.377.416.59.085.223.127.457.127.702v.335c0 .223-.032.43-.095.622a2.1'
                            '07 2.107 0 0 1-.32.527c-.138.18-.292.319-.462.415-.17.106-.362.186-.57'
                            '5.24l.702.51c.234.17.469.345.703.526Zm-8.281-4.228v2.425h6.494a.954.95'
                            '4 0 0 0 .4-.08.776.776 0 0 0 .334-.223c.107-.106.186-.218.24-.335.053-'
                            '.128.08-.266.08-.415v-.32a.954.954 0 0 0-.08-.398 1.232 1.232 0 0 0-.2'
                            '24-.351 1.228 1.228 0 0 0-.35-.224.954.954 0 0 0-.4-.08h-6.494Zm24.67-'
                            '.782c.106 0 .202.037.287.111a.37.37 0 0 1 .112.272.39.39 0 0 1-.112.28'
                            '7.425.425 0 0 1-.287.112h-3.64v4.579a.37.37 0 0 1-.111.272.348.348 0 0'
                            ' 1-.271.127.397.397 0 0 1-.288-.127.37.37 0 0 1-.111-.272V98.91h-3.639'
                            'a.37.37 0 0 1-.271-.111.39.39 0 0 1-.112-.287.37.37 0 0 1 .112-.272.37'
                            '.37 0 0 1 .271-.111h8.058Zm15.782-.048c.723 0 1.34.266 1.85.798.511.53'
                            '2.767 1.17.767 1.915v2.68a.37.37 0 0 1-.112.272.397.397 0 0 1-.287.127'
                            '.348.348 0 0 1-.272-.127.348.348 0 0 1-.127-.272v-1.196h-7.532v1.196a.'
                            '348.348 0 0 1-.128.272.348.348 0 0 1-.271.127.348.348 0 0 1-.271-.127.'
                            '348.348 0 0 1-.128-.272v-2.68c0-.745.255-1.383.766-1.915.51-.532 1.128'
                            '-.798 1.851-.798h3.894Zm-5.697 3.415h7.548v-.702c0-.532-.176-.984-.527'
                            '-1.357-.362-.383-.792-.574-1.292-.574H193.5c-.51 0-.942.191-1.293.574a'
                            '1.875 1.875 0 0 0-.542 1.357v.702ZM82.898 139.5h4.16l1.792-5.152h9.408'
                            'l1.824 5.152h4.448l-8.704-23.2h-4.288l-8.64 23.2Zm10.624-18.496 3.52 9'
                            '.952h-7.008l3.488-9.952Zm22.81 18.496h3.807v-17.216h-3.808v9.184c0 3.1'
                            '04-1.024 5.344-3.872 5.344s-3.168-2.272-3.168-4.608v-9.92h-3.808v10.84'
                            '8c0 4.096 1.664 6.784 5.76 6.784 2.336 0 4.096-.992 5.088-2.784v2.368Z'
                            'm7.678-17.216h-2.56v2.752h2.56v9.952c0 3.52.736 4.512 4.416 4.512h2.81'
                            '6v-2.912h-1.376c-1.632 0-2.048-.416-2.048-2.176v-9.376h3.456v-2.752h-3'
                            '.456v-4.544h-3.808v4.544Zm13.179-5.984h-3.809v23.2h3.808v-9.152c0-3.10'
                            '4 1.088-5.344 4-5.344s3.264 2.272 3.264 4.608v9.888h3.808v-10.816c0-4.'
                            '096-1.696-6.784-5.856-6.784-2.4 0-4.224.992-5.216 2.784V116.3Zm16.86 1'
                            '4.624c0-3.968 2.144-5.92 4.544-5.92 2.4 0 4.544 1.952 4.544 5.92s-2.14'
                            '4 5.888-4.544 5.888c-2.4 0-4.544-1.92-4.544-5.888Zm4.544-9.024c-4.192 '
                            '0-8.48 2.816-8.48 9.024 0 6.208 4.288 8.992 8.48 8.992s8.48-2.784 8.48'
                            '-8.992c0-6.208-4.288-9.024-8.48-9.024Zm20.057.416a10.32 10.32 0 0 0-.9'
                            '92-.064c-2.08.032-3.744 1.184-4.672 3.104v-3.072h-3.744V139.5h3.808v-9'
                            '.024c0-3.456 1.376-4.416 3.776-4.416.576 0 1.184.032 1.824.096v-3.84Zm'
                            '14.665 4.672c-.704-3.456-3.776-5.088-7.136-5.088-3.744 0-7.008 1.952-7'
                            '.008 4.992 0 3.136 2.272 4.448 5.184 5.024l2.592.512c1.696.32 2.976.96'
                            ' 2.976 2.368s-1.472 2.24-3.456 2.24c-2.24 0-3.52-1.024-3.872-2.784h-3.'
                            '712c.416 3.264 3.232 5.664 7.456 5.664 3.904 0 7.296-1.984 7.296-5.568'
                            ' 0-3.36-2.656-4.448-6.144-5.12l-2.432-.48c-1.472-.288-2.304-.896-2.304'
                            '-2.048 0-1.152 1.536-1.888 3.2-1.888 1.92 0 3.36.608 3.776 2.176h3.584'
                            'Zm6.284-10.688h-3.808v23.2h3.808v-9.152c0-3.104 1.088-5.344 4-5.344s3.'
                            '264 2.272 3.264 4.608v9.888h3.808v-10.816c0-4.096-1.696-6.784-5.856-6.'
                            '784-2.4 0-4.224.992-5.216 2.784V116.3Zm14.076 0v3.84h3.808v-3.84h-3.80'
                            '8Zm0 5.984V139.5h3.808v-17.216h-3.808Zm10.781 8.608c0-3.968 1.952-5.88'
                            '8 4.448-5.888 2.656 0 4.256 2.272 4.256 5.888 0 3.648-1.6 5.92-4.256 5'
                            '.92-2.496 0-4.448-1.952-4.448-5.92Zm-3.648-8.608V145.1h3.808v-7.872c1.'
                            '024 1.696 2.816 2.688 5.12 2.688 4.192 0 7.392-3.488 7.392-9.024 0-5.5'
                            '04-3.2-8.992-7.392-8.992-2.304 0-4.096.992-5.12 2.688v-2.304h-3.808Z" '
                            'fill="#F0F6FC"/><path stroke="#27303D" stroke-dasharray="10" d="M-5 48'
                            '0h325"/>',
                            shieldsAPI.getShieldSVG({
                                field: uint16(seed % 300),
                                colors: [
                                    uint24(colors & 0xFFFFFF),
                                    uint24((colors >> 24) & 0xFFFFFF),
                                    uint24((colors >> 48) & 0xFFFFFF),
                                    uint24((colors >> 72) & 0xFFFFFF)
                                ],
                                hardware: uint16((seed >> 9) % 120),
                                frame: uint16((seed >> 17) % 5)
                            }),
                            '<text font-family="A" x="50%" y="540" fill="#F0F6FC" style="font-size:'
                            '40px" dominant-baseline="central" text-anchor="middle">#',
                            _zfill(_tokenId),
                            '</text><rect class="i" mask="url(#a)" stroke="#27303D" stroke-width="2'
                            '" rx="20"/><circle class="j" stroke="#27303D"/><circle class="j" cy="6'
                            '20" stroke="#27303D"/></svg></g></svg>'
                        )
                    ),
                    '","attributes":[{"trait_type":"Used","value":',
                    "true",//ICurta(curta).hasUsedAuthorshipToken(_tokenId) ? "true" : "false",
                    "}]}"
                )
            )
        );
    }

    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------

    /// @notice Converts `_value` to a string with leading zeros to reach a
    /// minimum of 7 characters.
    /// @param _value Number to convert.
    /// @return string memory The string representation of `_value` with leading
    /// zeros.
    function _zfill(uint256 _value) internal pure returns (string memory) {
        string memory result = _value.toString();

        if (_value < 10) return string.concat("000000", result);
        else if (_value < 100) return string.concat("00000", result);
        else if (_value < 1000) return string.concat("0000", result);
        else if (_value < 10_000) return string.concat("000", result);
        else if (_value < 100_000) return string.concat("00", result);
        else if (_value < 1_000_000) return string.concat("0", result);

        return result;
    }
}
