// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibString } from "solmate/utils/LibString.sol";

import { ICurta } from "@/contracts/interfaces/ICurta.sol";
import { Base64 } from "@/contracts/utils/Base64.sol";

contract FlagRenderer {
    using LibString for uint256;

    function tokenURI(
        ICurta.PuzzleData memory _puzzleData/* ,
        address _author,
        uint256 _colors */
    ) external pure returns (string memory) {
        return string.concat(
            "data:application/json;base64," /*,
            Base64.encode(
                abi.encodePacked(
                    '{"name":"',
                    _puzzleData.puzzle.name(),
                    '","description":"',
                    '","image_data": "',
                    Base64.encode(
                        abi.encodePacked(
                            '<svg xmlns="http://www.w3.org/2000/svg" width="550" height="550" viewB'
                            'ox="0 0 550 550"><style>@font-face{font-family:A;src:url(data:font/wof'
                            'f2;charset-utf-8;base64,d09GMgABAAAAABIoABAAAAAAKLAAABHJAAEAAAAAAAAAAA'
                            'AAAAAAAAAAAAAAAAAAGjobkE4ci2AGYD9TVEFURACBHBEICqccoBELgRYAATYCJAOCKAQg'
                            'BYNuByAMBxt3I6OimvUVZH+VwJOd1yhF0zgE5TExCEqYGJiixbbnwP4dZ3ojLIOo9nusZ/'
                            'fRJ8AQgAICFZmKIpSpqJRPjvUpssca0NE7gG12KCpiscLIQJvXhQltNGlMwArs/BmdK5fV'
                            'h2tlJjmcJIfyqegIjKaFAkL2xmzu3G5f+LKucK0RgScgqNbInt05eA7IdyHLQlJ5ILKkAI'
                            '2LsmRUYiTh5D8sgBvNUikgepThvv9/7Vt9l9274oNYWrFooc1GREOjlHln5tu8NRvMZ1WE'
                            'JN6I4hZFQyGaVutEQvmh0iqJSMiE1ggNX4fm60G4VBK+hVS6yPZZNHETOvYf/6wI8AMAxS'
                            'aiREKCqKkRPT1iaEjMNZdYzh2CAK+6KbX/oC8NZO9cTOaDLAPg/gNAbl9N5AMKCBAGxaF4'
                            'IxHCbAZIOiZOprfyvA2svxHYCN8xFXIgBO2JgJBkCIqIycqraOuabY655plvgYUWWWyJFX'
                            'bwhFCsukQ59cgGY8Uaah88kjL5fx5QlZdkxUNbkDHIMQ++qS7D1nnyFUqhHlNMvSuZK1fX'
                            'qRhUhap69aRhnUyKyxTMwBwswBKswBpswPbkEbJ1HEqlntKpR3SrK716R994N1DVqeeMDo'
                            '7QrrukpSqSHZgDmAvzvM+v2ZzAQlgEi2EJWZsN0avrRGpFo5UcJiIGx7eiGrZDwnw0YhSk'
                            'HLviHr+vWx0joCfCKSOyA4H7P0c+r0GXbANfz4GrrMyyqmP3wDWW4+y7l4S762X1ZcwjQB'
                            'oOINXvM01OAf7nvsRQg0/rE+A09OW8FQJ4+UuJqyqznjiGunWqiav0+BQcegIjR2e5j2Vo'
                            'bwwvcie5j95yFcPCdxXG3bniECmQlY+G0onLqnE5DS6v7b2gZ4mitQ7WhOJHTYxPgMEWFy'
                            'bAIUDx8NO8gqIS0iKSADIiogBiACALcgDyAFIs+BXiIyikKF4YBJxNgexM0bwcHj5yCokJ'
                            'x0MQ4KIC6SEOEmq18Mvyy89HgP8PidnpugQNSdmjaFy+GJcMSlf4Ah5oXEtksEDvXgovEd'
                            'wBIgtEBviBYrA4vPyCwqLikkCkVaxstBbdr7aCAF2wB26Tv5ZdCzwhHtqe5nGikNjUSech'
                            '2B6UOBAO1bDSwsivQJsoFjJWicmn36MiJaFvvWhFeqy57HUgEUphEVsjMGJDGFXREWOxEo'
                            'fjPCliXRRB3WS0H+AVlcX3GTyC0n0fwWGX5vsENrNk3wewWCX5XsFkFPe9gDFa1PcIekTn'
                            'ewLVK/nqaBW9bsWjLIGg4ttD1jEkDgYSuSage1OPEAnn2F7zmWoV0dA4MSPis2P5kCECJk'
                            '18nngCMT+BvSY+X6IJy2dgJ4kvsDYKbK/AhogntE0/QbkGlkd8kfV9QNJmsEDii63/HrQ6'
                            '2JBY4kVwmW0dqNorftedTLNI/9Jwq8E8SEnWrpgFdteqYDJ9XG2eJUNcTB6su+JX1LfQZq'
                            'HilGkzYd1Vb4kSByBCFgA0FcB2iABI0X4/xbtD+J1UEN+ZoPFO+YJICNIy8z4j+rLM2wgN'
                            'zLklWiwtez2+AHI+9gGEcy3MK7eJBBZKWFDOEMW8OJ6ExdjdkHZ7ZkVYil/MtBgsS05lip'
                            '5noyTbtpWVRQrGxJ5JiTGZtUBisHeMbYCvo5P+ZL0/k2J2AMUAAhxw+2E/KqzTdmtx5F8g'
                            'gD9MGwHyBoDFoYHzk9QOBeIg9R3dvx6djJADLt/h1ykwhAHpAVlvgYXzrkIe4H5liJiWz9'
                            'Mk3l7DHUBRmBZUMzLPfKuRMHBEiyOQJEVm/cPGYGyyDNmQSDI+F/Xbu3pUT2q9lg0b1K9H'
                            'lw7tWkI4CnCR+qdvsh4enfkaYG6GcxjwBeAbAIBal+6LTXcrxeKEiunCi8zS+1uXOjYHoS'
                            'y4EXNuXkTrLUlJoxV2bJDH6MsjMRs2G8tvlsasojT2ocV1t2yIQlPwMtICCfpWK9WZO4Gt'
                            'w0u6s9hTS71G58ThjlakCzVBM+YjScM6npVwCfM87HwHH+taYCugEo46imBSKa2zVdcKK2'
                            'dXdqkxv+fATPp118TM+6zLjl8d9qi/nFU+7Z33ur7XwZ49VJKIDxrDoLtnrVnJqjCtyBzU'
                            'ORSvqlCwuWmQ4ZFzVkjuR+3LenE5OgrwP9z1ydHwC0fDuRDNSl4Su2swM0M9LZu6qPGvbF'
                            'WLJtQXztSmXWVsBMMwICeOrkmssuxQS5FuyYRyhEp4ENa2fggVisSS8hKz6+VFpnzeUf7n'
                            'Kpa16O6PwSSpY3rPB6lkYdmD2eiFl5fdD5UH7cvlUFsXSqADVrUGbd0qFemfJZd24YZXzP'
                            'OJLiRp4+AkEPTEmBlDDhuxbsWnSyzsqWL6qhuvebv4UDyR4ktUGqSewgqsJA8zzM+034SQ'
                            'LE6JQnFH2WMSFWX/Vjm3ScreuSFIcjRszN+KnHQh11XZAy7epzEf3CyIdsPSF2HD2o3ZYu'
                            'elKqikg6KzSHyV649Jnd4fc2iCgSBucqfLg2IO5RLfutpKusgmDxapq5HSpD5+la82KwhV'
                            'yt5s5uwS6/1rNoBtgOCIzT8kbSY36KqJKcgoulfNLFTbYPoNbvKgbg96Pb2qPjH70758+m'
                            'S13tbHYiV1G+/CA9mR8CT2hKIViO9KwYVq9oFYkOnvb5WViCClYQewYAHcAHH6YXP4Ijk+'
                            'ZH12N/Km7AiJ1FHBY9mdPusl8p9IdsP6MMCsMwx/zB8l45BuqXt1846SoAdDZt6noTlcl7'
                            'wAOl3rhrKSN9YaTvXLRN/euiWJb3YpB0vZ4tbnW4qlSBranIajAtSTVhxAq/hdmN+FKlMF'
                            'OGlqAFVadqEYTaqDvZE9nAQUYO7qVTS8a8mOmOnlseQ3x4kdT8+91dHd+tu2/tUJ29qTc2'
                            '2ZIUENg7SkVilBZOv2wILgtKHWgTTItPVLlQuh1+Sy+qzChxFD9fhnrxrw0DcU2mORFxFY'
                            'iQlKQWyur/h376Bx3LLs8I9P17x9vlyNd1J6XDfiycouNOQtAQoOWy59fnXCDf/61J4vmX'
                            'jLq6odtfavXtXaKbSdd4aTgAIqHnAHTIQ4ofkJXMOCAqkmTag4Knf3pw2v8dMDVoeODFp6'
                            'TL35Y3mqYjqCNszj0QZnQitpIH4SktQankeXnGkuiBgd5Jy3EUiVyAxjfS1sxBOKs3KK25'
                            'KUCGRz/crlPZLhvYJb1oup/FOtyNBL0nKp/Dl3RUlet79/LX1RhiTP2sCQsSGhcy29Arez'
                            '6znwSWlRdXWQ8QdGItUXZksngzk5y3J/dwIK2B+xyzHCyQA1g6ReIfVeYyPlVk9GSkZvNv'
                            'lObR3lfl8e2GmoPSOszzM/vFngbjt+u+Z38MG9Ap2Tglef6yAqoK8jLFowHBs6AdwrJYx9'
                            '0+xUYq5JWIA8nqyrXjx3dEscaHkUFcUCCphiG23zHzbN9LwpLkCsXYxta++aqI1sotDaQc'
                            'sTAAWxgAKwzVN74HVkgfX27QLHyA/ugUNYB76rmdlfQnpUVU163F+amT1QiuDqqvRvrYES'
                            'WANxiACMYdHpuiI1b2SRXxRT2ozVQQtqZJZCQFGsl/aFrQFJtrSEFgb4gTubmqwkhrthdv'
                            'kUDEDd0G39rHWlgNcalyI15aPaY7LzO2II7mx6DFbM7rbppZswDNUd5xUSV2TtnoDnxZLM'
                            'WBCHiA0Y67zX/ZPNT0vyRVYuxrY1dI8XkBr9Itugzc1biCVQFQnYLES4t4a/GkXrqkYeVq'
                            'cMg7Upy9dLXTPKqJ46HQpDTy0LH8j8NVn9Zq59XkbaBBxn9L/d/bnnJhEIe65Gfvv6lfFt'
                            'zzUCac/NyB9f7dfvZiZ85visjuTuv5MJPPjM9lsdAbd0ABQkgXiz9F1L2u/tsCR9dIXDLe'
                            '32aKQzAipafZicZgqlOYZxaFbdvvPUWVzrhNREUsCd2zJH90dyZYV24EBSuU74/4CE2EQ6'
                            'ksLKHPSI4o/6RpRDEIQyqleIBYtqizt7vEJKIBD8CXk1OyLDuz0YQhE6R3R8H9Kt4dgZs5'
                            'ZBRAdMnH4xqI25pvpUBPZPHJSltUJdlr4dPezrQJPO/92YvZZRWVdFC0FsKBxQALj7Ksed'
                            'mlYkxEajJbOPdFXyRlmMWUiAJNb8JDchBGa32RPsxBc0BuwSHNWk7d3PBQrXtKeGLY+cWn'
                            'P2XgBHvEoDyLPvPS4UgqKEoP2CikHjygGj5mXxLQM85ZSJqqIrjxPAXdYioD378Fb+gtr4'
                            'sAkcgBOreJ/luya88RjWPAiAFzk7GsUjV7pExTnWAAliGfPjOwFhl7pH9pNdgAW42HEPgf'
                            '19lXuBjQeRMAh5CdcO1qVtku3UOvgbBqFz9pttzbEjNjVz37qGDv9u05JN27Rel3gtf+gQ'
                            '0r/xjmrSKCGsFsKAwWwao/P443RmEzAgLKxmjCjhMRhe50MthUAIIBfVe0YwGjxJRRAAgZ'
                            'SSBl/AXVdpACz73sPCLAWQiO+6oKrfuHrQqHlZYvMoTzljoqboypMEr5WNzDnscSJDxrB+'
                            'fMXVZ+WuadxENHOOD3E7k5EdRPMdq4EQw5wdq9R9W1CgELL4WGHM5Jl54BbQL2LaE7GHr5'
                            'sKyAZuzyMNvXa52B1Ay5aQ/FwIgaD6ACGBBbkQJO3MYjqKLnh2cXkQDHkkD6T0Tkz2BSVi'
                            '0vPfdvSf/DNxIxk0SvfJ07AjtBzK4MmFncKZxcnwP9DO2Jyp6fnsOYj2REmMvlFa+IiHpJ'
                            'XFUIJbENNlK9+XTI2l+Hwa/HzwwOHnR+v8XAuK86K95grRX8+DsVzFef+URghHYhPdacGp'
                            'Xo5OGV4xKXtSAuJ3OOAiPSl+CVux3yA8tf4oJTtnLyW2MiAkN50rgy6WqSphR2Q0XKIAaf'
                            'Ek7J/ayPXok7hxtnbxk2jwx3d40JHLP0JPaBSJ+OGTuMMnOJXhR0jnhNtEGcw9NnLa9vq8'
                            'gvqflnKBnR9/OoTTGy1ImjzDAAe50ClcpZB8tnmPEHm/tHn+zd6N5X8/MXEe6fnjDWiDHS'
                            'NEBm88mNXNjU+aOMuqOBaUxfX1TmcHOYabOvipI3ak8aBJ/RIXTT4fekn9EQ9M5SqukjKr'
                            'gjjNjQI5FAeTVOZPExQd8BVmrfvyi2j+KWVsDCpxw65GVlBG1WVS2W63EG0rvOF/qfQAx3'
                            'BdnIepazwx4rYf28vRgeVDIEX6ODgyvOIGraSdncJVZpPPNu0WIu+/bl55sW9j2d9PDNy2'
                            'jNyJekmjQ/1ENn88mNnNTUiYPMsoP+YYYY4jWnsmc0PwEda2RAnE9gd82HsCBf8EooDkc3'
                            'jWBlnrw/vnY4C1Dr8vfDfJK8qWTXyCCv6fjFjFGtaxgU1sYRs72CUVSwPWsIEt7GCXci31'
                            '24AqsIZ1bGATW9jGzohuTgCE/o9XfeCd/xvTsv2BwP+TjdPeYCCk30jV4P+dKQI9GSFp3q'
                            'ePQUh/awUI1lFcFAHLLXuXTAHlGOgG0Dvf2Z+n5UzCSNAfIyGPN3bOeF/9PVIcRUPhSOh6'
                            'tKVcGMmKsbevN84MEsu+Lhh1f59JkajfBk9pPgMnx/e3M9A+R3HUZsstexfbDgVjFwB99w'
                            'TovLN9/Cs5Qs75W0d5CQC++bx7HYBvj5Kufrv/W6gSKw2ARQEQ/C8luPB4xOLz5x4A4Xiy'
                            '65cCY8v0FbZNTj6fzTyZvsPJcTqQhJBpczx5isTxnayxWPq4z1q7a22ckZ5h0QkN18ZZL/'
                            '7wo5k3086aBm+t41Vjk3F6MlT14xfYPWl6PKZImZQ9vN/1i2mTWhoZdCsfhZPOYrSub29a'
                            'OZjBgjMdOd3FwDu5v+WeQSibhd5F/nrwjIrzgiDAertIu0CihGdoEuBzlyhJSYB7AOsm8u'
                            '65KUFv3bSpD6oa426m2X52teRDKx1CDvzhCjcMb3hXkc93mQhl4aDxIBAvQ6IYUaIl0zA1'
                            'DkrZzhZwsq/Dl4wj0e5uq0QCsThYTGWZlMii/6MVm0RDO4Ngdx8viaORkeNiRnefgsnMYQ'
                            'I85lB4khB0MnN1w1mUHTjm247hTiAOGwVHlBRxGBJZGxqbmGeB7aj8UDlJ+U2JvzjjtmMI'
                            '8GmQpO9TbmrsIFsTY7MdZeFQNhKgK5lM1STySmSEiTrO6X8Ln0n5Lv4Vj6wGAA==)}@fon'
                            't-face{font-family:B;src:url(data:font/woff2;charset-utf-8;base64,d09G'
                            'MgABAAAAAAhQABAAAAAAD4gAAAf2AAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGhYbhCocUA'
                            'ZgP1NUQVRIAHQRCAqPQIx0Cy4AATYCJANYBCAFg1YHIAwHG/YMUZRR0hhkPxNMlbEboUgq'
                            '+fBI0pEkVMwtRsc8kTqPvob/GX6NoH7st/e+aHLMEyXSaHjI5tU7oVEJRaw0mk2nBHj/P2'
                            '7694UIJFCoHdq50ok6paJURELVmdGOUTWmxtTDXPn9zPxom4glMvErMJW4alpRu79ZXw6U'
                            'tFRH/wP4wv6/tVZ3013cAY9nCTwkHhFCIlPKnxP7J3PoDKpJxLtGOqGIyGnDsiZIBUIhtM'
                            'hTmqVhJtyMGedU9E0+RQBNABIEsYYgoG6AMbCFBeszo257Y86ocMBvxbAtP8gZBbBEOEyD'
                            'oQ1DoYwEq3ZEjMdbW2SsoQwLL9UhNpGWBcwcl5DPdS1HrnGR9VrcRDbPruGaAV4JWAbmEq'
                            'eVSq7ZMHXB1nex0hbQ7QIMGoIBRSRh5+0YDIXAw8cnIpISHHITgyjoEDy8B/JkgkRVMjPz'
                            'T0ne3bgMTGT5pDwUY8MWguETwiujkBoBKnOkFvhQmsKnmteaEAWYWD5Z4+HCpeXNialh5V'
                            'Nv+btjzhGmFhB3gDI+YIIQClkOOkqaOegsIERWDHC0nRNKUiu0EeCAkCI1SO+AE4ipIPIV'
                            'YOpAkCGiaJwXSj7pfs51YvNESuDpkwVAc2RxpYRAv9NtV69OtSqVdLQhmCmgnBPDnjp9Hp'
                            'gAaRGYwgN4i0LEjm6MCA/yIm5l/dGcHT5ukKVUUrUMxoUUjvZBN7psscGtpPxTq/D4bFn6'
                            'FhxEFz65g2XefcoU3UZFwXAXP6GLn93jZd1/Lip6ajQyrPgy8C6k33lCWyDxCB/K0OgsTG'
                            'KThMmsLuw4pBuRzJcbjRKoJz675ShyM8IaR8dbz4jdf85bnhrlYYVT2BnD0GMZQhnGvnWO'
                            'jwKmaDOIpBG9neMc9Tiq4LBwHGe9E8MyOLNNYIlkcOGtW6No8Ey/60O677y3abuTVPjsnh'
                            '9qqYNxJEMwSXO5Y3y/A8ZPGNPzLoAVsszIg05NKXOFnMNODMskJRfGSkdB50AuxIVJEMXS'
                            'iYsB4nhFEptEs/2FwESO8kv7S4xPCzIqBnJLp3Z2bpOwu7B2Ua3WGKwZTRqj011j8oxzIp'
                            'PHha8aCJpgXUCCXJmkQtrOSuUNnBlHLLWvo3k0x9g9NCkk0zPtzybSyaIkhg2a8EEKIy9U'
                            'KCZclMjhOlbA8MtvYnFa4MsODySK8Cs+J/27bXBorTb80ET/gyMObQ+j6SMQO+jPoelfaJ'
                            '1t0Pfuuo3f7ndInLeS5f/e3p43DwAYuRUA/r8bv0JDgd3msXUbu+/Zs1HqUNUlezKk4Zyn'
                            'y3aWdd133rdpN1ADRpys6J1V0ac3rwLkuWBZ/q/5YP4FReQW5ZoVseyyPFnp1YkrbU4t3p'
                            '0ad1rd1MEsqTQ9mFWy9w/TDIKYfM2NRcmlT92ymiL9o9IOrAzp+Wvh//Ok/652HIRppafO'
                            'jC3e/QnXwtb+G/4LL7qhyQ5o6HS/MSpYVGSpt1o1cjJ/U019feuxjYPWPl45teicrmtG7B'
                            'JDv90hCXf3fTZdE0ZFRB1Y6X2z2BCm7PS689S3R6ZNssU6V6ZqnFegC7tXBd8pYPpsU+6m'
                            '0is1JwYfb/T5+LnRd+AJw6YdSs/ULT1MvH96P/7JTaWbzuh86YY6JX6mQqM+qfbBwMHQxz'
                            'AKRrLPHzVA6+ITGr3STVVu89kEfHhh6rHFsGWHMuZm6QLWTN8xFsYztQYA+tU1+NJndDB+'
                            '9s0ezTrVoTSZOgInXLiW+HblsZ1RA2/71lzanul/8XBcesmlwrCHafn6RPNtVZm7ZlxYcM'
                            '+Vz2f2j2nV//CCO0CCCUigFsJ8pfucOUr3+RQC7BrN6y+rbh9w8aZNr5MjgA+pnKb41lw/'
                            '8qQOeiyCusn8nV6YbUYnG/M1FRfyJyVLpsS/L268QoAYN+FtB9an1u04sfmNuUdWa02uW5'
                            'W3V0eUAXrM1elMWi8yPvZ+qV73NjUDTl0zGfYcutAQtd3b7xCMS+9zbdJpvU+XWe9HzmsP'
                            '7mfu4kAXXb1ZdbHWm9JqvQUX66uqjkD0YaeaOwW3ZwJ/1ovPPd6CDdmMgPmzpqYsXvmNZG'
                            'jU/ZLCbsuRg3nnOuHoSL2bb13gJZi4AM71OPc6wgTEft8pSrc+4wbbPRt9M1FuNcf3qFy1'
                            'LReWYLHF+SgmXJL0eZ1e/Tg17fKWw2c3Ou11Vh0ANxL654L5qIFu2eck/kDEzGnuVnZTr8'
                            'ptsxj/wGGxwxMGVHy/h5x5Mjw+Q9e2FPjZMIubRWZfGrtooUym+FjZQvrqYxfOA9vclhZu'
                            '1qXt/P6O9b6hupPn9Ry3PTSR9fFJTycGEECh+PB3s7bZUzztizLMAOD746FhAH7kq37/J7'
                            '9VI7EQgDIMIMA/MRs9B/Xnz5P/q/nfq5t9V8A9xYfvchFqyHGgJjnNkZI9UA3AdFqI3+6Q'
                            'ckegVpOREqmoyd0+3E61AmyUfZtlfcBL/bB44l2MhC8goGcTCEWSQ2KJ31aXioeKAgC3AA'
                            '8DQlMbMBa0Bh6ZFgOumzsGwgQf9aRuMSQFEoMw5hgkQMcKlLoLda5C6QNEAiFEjCE7ij7W'
                            'NWRv4GI55AEQq4C8PeZxhGK2B7FQUwAKOMSBQCUTC6OrsgDRIJW02jp85uWZrlBkKHiDHM'
                            '/Xg/zFI0/gIWUBQ6PIOJhsqjVONk6WsEh7Pr4zO4JXtRkVKeSIU0uSok0mEmMOtIMT+OlR'
                            'ClJ9471uzlPTJCrkYX7/PQbo/Iz+3axYAg==)}text,tspan{dominant-baseline:cen'
                            'tral}.a{font-family:A;letter-spacing:-.05em}.b{font-family:B}.c{font-s'
                            'ize:16px}.d{font-size:12px}.f{fill:rgb(',
                            '181e28', // Fill
                            ')}.h{fill:rgb(',
                            'f0f6fc', // Primary text
                            ')}.i{fill:rgb(',
                            '94a3b3', // Secondary text
                            ')}.j{fill:none;stroke-linejoin:round;stroke-linecap:round;stroke:#9'
                            '4a3b3}</style><path d="M0 0h550v550H0z" style="fill:rgb(',
                            '181e28', // Background
                            ')"/><rect x='
                            '"143" y="69" width="264" height="412" rx="8" fill="rgb(',
                            '27303d', // Border
                            ')"/><re'
                            'ct class="f" x="147" y="73" width="256" height="404" rx="4"/><rect cla'
                            'ss="h" x="319" y="97" width="64" height="24" rx="12"/><path class="f" '
                            'd="M334.192 103.14c.299-.718 1.317-.718 1.616 0l1.388 3.338 3.603.289c'
                            '.776.062 1.09 1.03.5 1.536l-2.746 2.352.838 3.515c.181.757-.642 1.355-'
                            '1.306.95L335 113.236l-3.085 1.884c-.664.405-1.487-.193-1.306-.95l.838-'
                            '3.515-2.745-2.352c-.591-.506-.277-1.474.5-1.536l3.602-.289 1.388-3.337'
                            'zm16 0c.299-.718 1.317-.718 1.616 0l1.388 3.338 3.603.289c.776.062 1.0'
                            '9 1.03.5 1.536l-2.746 2.352.838 3.515c.181.757-.642 1.355-1.306.95L351'
                            ' 113.236l-3.085 1.884c-.664.405-1.487-.193-1.306-.95l.838-3.515-2.745-'
                            '2.352c-.591-.506-.277-1.474.5-1.536l3.602-.289 1.388-3.337zm16 0c.299-'
                            '.718 1.317-.718 1.616 0l1.388 3.338 3.603.289c.776.062 1.09 1.03.5 1.5'
                            '36l-2.746 2.352.838 3.515c.181.757-.642 1.355-1.306.95L367 113.236l-3.'
                            '085 1.884c-.664.405-1.487-.193-1.306-.95l.838-3.515-2.745-2.352c-.591-'
                            '.506-.277-1.474.5-1.536l3.602-.289 1.388-3.337z"/><text class="a h" x='
                            '"163" y="101" font-size="20">Puzzle #1</text><text x="163" y="121"><ts'
                            'pan class="b d i">Created by </tspan><tspan class="a d h">',
                            'A85572C', // Author
                            '</tsp'
                            'an></text><rect x="163" y="137" width="224" height="224" fill="rgba(0,'
                            '0,0,0.2)" rx="8"/><path class="j" d="M176.988 387.483A4.992 4.992 0 0 '
                            '0 173 385.5a4.992 4.992 0 0 0-3.988 1.983m7.975 0a6 6 0 1 0-7.975 0m7.'
                            '975 0A5.977 5.977 0 0 1 173 389a5.977 5.977 0 0 1-3.988-1.517M175 381.'
                            '5a2 2 0 1 1-4 0 2 2 0 0 1 4 0z"/><text class="a c h" x="187" y="383">',
                            'A85572C', // Captured by
                            '</text><text class="b d i" x="187" y="403">Captured by</text><pa'
                            'th class="j" d="m285.5 380 2 1.5-2 1.5m3 0h2m-6 5.5h9a1.5 1.5 0 0 0 1.'
                            '5-1.5v-8a1.5 1.5 0 0 0-1.5-1.5h-9a1.5 1.5 0 0 0-1.5 1.5v8a1.5 1.5 0 0 '
                            '0 1.5 1.5z"/><text class="a c h" x="303" y="383">',
                            'A85572C', // Solution
                            '</text><text c'
                            'lass="b d i" x="303" y="403">Solution</text><path class="j" d="M176 43'
                            '7.5h-6m6 0a2 2 0 0 1 2 2h-10a2 2 0 0 1 2-2m6 0v-2.25a.75.75 0 0 0-.75-'
                            '.75h-.58m-4.67 3v-2.25a.75.75 0 0 1 .75-.75h.581m3.338 0h-3.338m3.338 '
                            '0a4.97 4.97 0 0 1-.654-2.115m-2.684 2.115a4.97 4.97 0 0 0 .654-2.115m-'
                            '3.485-4.561c-.655.095-1.303.211-1.944.347a4.002 4.002 0 0 0 3.597 3.31'
                            '4m-1.653-3.661V428a4.49 4.49 0 0 0 1.653 3.485m-1.653-3.661v-1.01a32.2'
                            '26 32.226 0 0 1 4.5-.314c1.527 0 3.03.107 4.5.313v1.011m-7.347 3.661a4'
                            '.484 4.484 0 0 0 1.832.9m5.515-4.561V428a4.49 4.49 0 0 1-1.653 3.485m1'
                            '.653-3.661a30.88 30.88 0 0 1 1.944.347 4.002 4.002 0 0 1-3.597 3.314m0'
                            ' 0a4.484 4.484 0 0 1-1.832.9m0 0a4.515 4.515 0 0 1-2.03 0"/><text><tsp'
                            'an class="a c h" x="187" y="433">',
                            '16', // Rank
                            ' </tspan><tspan class="a d i" y="43'
                            '5">/ ',
                            '221', // Solvers
                            '</tspan></text><text class="b d i" x="187" y="453">Rank</text>'
                            '<path class="j" d="M289 429v4h3m3 0a6 6 0 1 1-12 0 6 6 0 0 1 12 0z"/><'
                            'text class="a c h" x="303" y="433">',
                            '44:34:39', // Solve time
                            '</text><text class="b d i" '
                            'x="303" y="453">Solve time</text></svg>'
                        )
                    ),
                    '","attributes":[{"trait_type":"Puzzle","value":"',
                    _puzzleData.puzzle.name(),
                    '"},{"trait_type":"Author","value":"',
                    '"},{"trait_type":"Phase","value":"',
                    '"},{"trait_type":"Solver","value":"',
                    '"},{"trait_type":"Solve time","value":"',
                    '"},{"trait_type":"Rank","value":"',
                    _tokenId.toString(),
                    '"}]}'
                )
            ) */
        );
    }
}
