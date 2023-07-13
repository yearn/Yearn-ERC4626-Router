pragma solidity 0.8.10;

import {ERC20, MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import {MockVaultV3} from "../mocks/MockVaultV3.sol";
import {MockYearnV2} from "../mocks/MockYearnV2.sol";
import {WETH} from "solmate/tokens/WETH.sol";

import {IERC4626Router, Yearn4626Router, IYearnV2} from "../../Yearn4626Router.sol";
import {IERC4626RouterBase, Yearn4626RouterBase, IWETH9, IERC4626, SelfPermit, PeripheryPayments} from "../../Yearn4626RouterBase.sol";

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import "forge-std/Test.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    Yearn4626Router private router;
    IERC4626 private vault;
    MockERC20 private underlying;
    address private user = address(11);

    mapping(bytes32 => uint256) private calls;
    uint256 private ghost_deposit;
    uint256 private ghost_mint;
    uint256 private ghost_witdhraw;
    uint256 private ghost_redeem;
    uint256 private ghost_deposit_to_vault;
    uint256 private ghost_zero;

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    constructor(Yearn4626Router _router, IERC4626 _vault, MockERC20 _underlying) {
        router = _router;
        vault = _vault;
        underlying = _underlying;

        underlying.mint(user, type(uint256).max);
    }

    function deposit(
        uint256 amount
    ) public countCall("deposit") {
        amount = bound(amount, 0, 1e30);
        if (amount == 0 || amount > underlying.balanceOf(user)) return;

        router.approve(underlying, address(vault), amount);

        vm.prank(user);
        underlying.approve(address(router), amount);
        vm.prank(user);
        router.pullToken(underlying, amount, address(router));

        vm.prank(user);
        router.deposit(vault, amount, user, amount);

        ghost_deposit += amount;
    }

    function mint(
        uint256 amount
    ) public countCall("mint") {
        amount = bound(amount, 0, 1e30);
        if (amount == 0 || amount > underlying.balanceOf(user)) {
            ghost_zero++;
            return;
        }

        router.approve(underlying, address(vault), amount);

        vm.prank(user);
        underlying.approve(address(router), amount);
        vm.prank(user);
        router.pullToken(underlying, amount, address(router));

        vm.prank(user);
        router.mint(vault, amount, user, amount);

        ghost_mint += amount;
    }

    function withdraw(
        uint256 amount
    ) public countCall("withdraw") {
        amount = bound(amount, 0, vault.balanceOf(user) / 10);
        if (amount == 0) {
            ghost_zero++;
            return;
        }

        vm.prank(user);
        vault.approve(address(router), amount);
        vm.prank(user);
        router.withdraw(vault, amount, user, amount);

        ghost_witdhraw += amount;
    }

    function redeem(
        uint256 shares
    ) public countCall("redeem") {
        shares = bound(shares, 0, vault.balanceOf(user) / 10);
        if (shares == 0) {
            ghost_zero++;
            return;
        }

        vm.prank(user);
        vault.approve(address(router), shares);

        vm.prank(user);
        router.redeem(vault, shares, shares);

        ghost_redeem += shares;
    }

    function depositToVault(
        uint256 amount
    ) public countCall("depositToVault") {
        amount = bound(amount, 0, 1e30);
        if (amount == 0 || amount > underlying.balanceOf(user)) {
            ghost_zero++;
            return;
        }

        router.approve(underlying, address(vault), amount);
        vm.prank(user);
        underlying.approve(address(router), amount);
        vm.prank(user);
        router.depositToVault(vault, amount, user, 1);

        ghost_deposit_to_vault += amount;
    }

    function callSummary() external view {
        console.log("Call summary:");
        console.log("-------------------");
        console.log("deposit", calls["deposit"]);
        console.log("mint", calls["mint"]);
        console.log("withdraw", calls["withdraw"]);
        console.log("redeem", calls["redeem"]);
        console.log("depositToVault", calls["depositToVault"]);
        console.log("zero runs ", ghost_zero);
        console.log("-------------------");

        console.log("Deposit amount: ", ghost_deposit);
        console.log("Mint amount: ", ghost_mint);
        console.log("Withdraw amount: ", ghost_witdhraw);
        console.log("Redeem amount: ", ghost_redeem);
        console.log("Deposit to vault amount: ", ghost_deposit_to_vault);
    }
}

contract ERC4626RouterInvariantTest is Test {
    MockERC20 underlying;
    IERC4626 vault;
    Yearn4626Router router;
    IWETH9 weth;
    Handler handler;

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);
        vault = IERC4626(address(new MockVaultV3(underlying)));
        weth = IWETH9(address(new WETH()));
        router = new Yearn4626Router("TestYearn4626Router", weth);
        handler = new Handler(router, vault, underlying);

        targetContract(address(handler));
    }

    function invariant_zeroBalance() public {
        assertEq(underlying.balanceOf(address(router)), 0);
        assertEq(underlying.allowance(address(handler), address(router)), 0);
        assertEq(vault.allowance(address(handler), address(router)), 0);
        handler.callSummary();
    }
}
