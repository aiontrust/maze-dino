// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Draws a MAZE DINO as an SVG straight from its 8-digit DNA number.
/// Digits (left to right): 1-2 color, 3 eyes, 4 back, 5 pattern, 6 accessory, 7-8 reserved.
/// The output must match tools/dino_ref.py byte for byte (checked by the tests).
library DinoRenderer {
    bytes private constant BODY  = "#ff2fa8#8e5bff#2fd6a0#ffb22f#3fa9ff#ff6a5c#8fd62f#4fd0e0";
    bytes private constant DARK  = "#c72583#6f47c7#25a77d#c78b25#3184c7#c75348#70a725#3ea2af";
    bytes private constant LIGHT = "#ffa1d8#ccb5ff#a1edd4#ffdca1#a9d8ff#ffbcb6#cdeda1#b0eaf1";

    // ----- trait decoding (any 8-digit number is a valid dino) -----
    function colorOf(uint32 dna)   internal pure returns (uint8) { return uint8((dna / 1_000_000 % 100) % 8); }
    function eyesOf(uint32 dna)    internal pure returns (uint8) { return uint8((dna / 100_000 % 10) % 4); }
    function spikesOf(uint32 dna)  internal pure returns (uint8) { return uint8((dna / 10_000 % 10) % 4); }
    function patternOf(uint32 dna) internal pure returns (uint8) { return uint8((dna / 1_000 % 10) % 4); }
    function accOf(uint32 dna)     internal pure returns (uint8) { return uint8((dna / 100 % 10) % 5); }

    function svg(uint32 dna) internal pure returns (string memory) {
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-100 -100 200 200">',
            '<rect x="-100" y="-100" width="200" height="200" fill="#fff0f8"/>',
            '<g transform="translate(6 14)">', _dino(dna), '</g></svg>'
        );
    }

    function _dino(uint32 dna) private pure returns (string memory) {
        uint8 c = colorOf(dna);
        string memory body = _pick(BODY, c);
        string memory dark = _pick(DARK, c);
        return string.concat(
            _spikes(spikesOf(dna), dark),
            _torso(body, dark, _pick(LIGHT, c)),
            _pattern(patternOf(dna), body, dark),
            _head(body, dark, eyesOf(dna)),
            _accessory(accOf(dna))
        );
    }

    function _pick(bytes memory list, uint8 i) private pure returns (string memory) {
        bytes memory out = new bytes(7);
        for (uint256 k = 0; k < 7; k++) out[k] = list[uint256(i) * 7 + k];
        return string(out);
    }

    function _spikes(uint8 style, string memory dark) private pure returns (string memory) {
        if (style == 1) return string.concat(
            _poly("-26.7,-6.1 -31.7,4.8 -37.3,-4.5", dark),
            _poly("-16.7,-14.8 -25.9,-7.1 -27.1,-17.9", dark),
            _poly("-4.0,-18.5 -15.6,-15.4 -12.1,-25.7", dark));
        if (style == 2) return string.concat(
            _poly("-25.8,-7.9 -32.6,6.6 -42.8,-7.0", dark),
            _poly("-15.2,-16.1 -27.4,-5.8 -30.9,-22.5", dark),
            _poly("-2.0,-19.0 -17.5,-14.9 -13.6,-31.5", dark));
        if (style == 3) return string.concat(
            _bump('cx="-31.9" cy="-1.9"', dark),
            _bump('cx="-23.2" cy="-13.3"', dark),
            _bump('cx="-10.5" cy="-19.9"', dark));
        return "";
    }

    function _poly(string memory pts, string memory dark) private pure returns (string memory) {
        return string.concat('<polygon points="', pts, '" fill="', dark, '"/>');
    }

    function _bump(string memory at, string memory dark) private pure returns (string memory) {
        return string.concat('<circle ', at, ' r="6" fill="', dark, '"/>');
    }

    function _torso(string memory body, string memory dark, string memory light) private pure returns (string memory) {
        return string.concat(
            '<path d="M-26 8 C-50 20 -64 6 -56 -10 C-50 0 -40 0 -26 -10 Z" fill="', body, '"/>',
            '<ellipse cx="-2" cy="12" rx="30" ry="30" fill="', body, '"/>',
            '<ellipse cx="5" cy="18" rx="17" ry="20" fill="', light, '"/>',
            '<ellipse cx="-14" cy="41" rx="11" ry="7" fill="', dark, '"/>',
            '<ellipse cx="11" cy="41" rx="11" ry="7" fill="', dark, '"/>'
        );
    }

    function _pattern(uint8 style, string memory body, string memory dark) private pure returns (string memory) {
        if (style == 1) return string.concat(
            _spot("-16", "-4", "3.5", dark), _spot("-22", "12", "3", dark), _spot("-14", "26", "3.5", dark));
        if (style == 2) return string.concat(
            _stripe("-14", "-4", dark), _stripe("-20", "10", dark), _stripe("-14", "24", dark));
        if (style == 3) return string.concat(
            _spot("0", "8", "2.6", body), _spot("10", "12", "2.6", body), _spot("4", "20", "2.6", body),
            _spot("12", "26", "2.6", body), _spot("-2", "30", "2.6", body));
        return "";
    }

    function _spot(string memory x, string memory y, string memory r, string memory fill) private pure returns (string memory) {
        return string.concat('<circle cx="', x, '" cy="', y, '" r="', r, '" fill="', fill, '"/>');
    }

    function _stripe(string memory x, string memory y, string memory dark) private pure returns (string memory) {
        return string.concat('<path d="M', x, ' ', y, ' q-10 8 -4 18" stroke="', dark,
            '" stroke-width="3.5" fill="none" stroke-linecap="round"/>');
    }

    function _head(string memory body, string memory dark, uint8 eyes) private pure returns (string memory) {
        return string.concat(
            '<rect x="-8" y="-42" width="58" height="38" rx="19" fill="', body, '"/>',
            '<path d="M17 4 q9 1 10 9 M17 4 q-1 8 7 11" stroke="', dark, '" stroke-width="3" fill="none" stroke-linecap="round"/>',
            _eyes(eyes),
            '<path d="M30 -19 Q38 -13 45 -21" stroke="#111" stroke-width="2.6" fill="none" stroke-linecap="round"/>',
            '<circle cx="45" cy="-33" r="1.6" fill="', dark, '"/>'
        );
    }

    function _eyes(uint8 style) private pure returns (string memory) {
        if (style == 2) return '<path d="M26 -30 q5 4 10 0" stroke="#111" stroke-width="2.6" fill="none" stroke-linecap="round"/>';
        if (style == 1) return '<circle cx="31" cy="-30" r="5.2" fill="#111"/><circle cx="33" cy="-32" r="1.8" fill="#fff"/><circle cx="29.5" cy="-28" r="1" fill="#fff"/>';
        string memory dot = '<circle cx="31" cy="-30" r="3.4" fill="#111"/><circle cx="32" cy="-31" r="1" fill="#fff"/>';
        if (style == 3) return string.concat(dot, '<circle cx="25" cy="-19" r="4" fill="#ff7aa8" opacity=".6"/>');
        return dot;
    }

    function _accessory(uint8 a) private pure returns (string memory) {
        if (a == 1) return '<polygon points="10,-40 34,-40 22,-72" fill="#ffd23f"/><circle cx="22" cy="-73" r="4.5" fill="#ff2fa8"/><path d="M14 -48 h16 M17 -57 h10" stroke="#fff" stroke-width="2.5"/>';
        if (a == 2) return '<polygon points="12,-42 -4,-54 -4,-32" fill="#ffd23f"/><polygon points="12,-42 28,-54 28,-32" fill="#ffd23f"/><circle cx="12" cy="-42" r="4.5" fill="#e0a800"/>';
        if (a == 3) return '<circle cx="31" cy="-30" r="9" fill="none" stroke="#222" stroke-width="2.6"/><path d="M22 -30 L8 -34" stroke="#222" stroke-width="2.6" stroke-linecap="round"/>';
        if (a == 4) return '<polygon points="10,-41 10,-62 19,-52 27,-64 35,-52 44,-62 44,-41" fill="#ffd23f" stroke="#e0a800" stroke-width="2"/>';
        return "";
    }
}
