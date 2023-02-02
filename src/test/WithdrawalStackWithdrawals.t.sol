pragma solidity 0.8.10;

import {ERC20, MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

import {MockYearnV3} from "./mocks/MockYearnV3.sol";
import {MockStrategy} from "./mocks/MockStrategy.sol";

import {WETH} from "solmate/tokens/WETH.sol";

import {IYearn4626Router, Yearn4626Router} from "../Yearn4626Router.sol";
import {IYearn4626RouterBase, Yearn4626RouterBase, IWETH9, IYearn4626, SelfPermit, PeripheryPayments} from "../Yearn4626RouterBase.sol";

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

interface Assume {
    function assume(bool) external;
}

contract WithdrawalStackWithdrawals is DSTestPlus {
    MockERC20 underlying;
    IYearn4626 vault;
    IYearn4626 toVault;
    Yearn4626Router router;
    IWETH9 weth;
    IYearn4626 wethVault;
    MockStrategy mockStrategy;

    bytes32 public PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    receive() external payable {}

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        vault = IYearn4626(address(new MockYearnV3(underlying)));
        toVault = IYearn4626(address(new MockYearnV3(underlying)));

        mockStrategy = new MockStrategy(underlying);

        MockYearnV3(address(vault)).addStrategy(address(mockStrategy));

        weth = IWETH9(address(new WETH()));

        wethVault = IYearn4626(address(new MockYearnV3(weth)));

        router = new Yearn4626Router("", weth); // empty reverse ens

        // set gov to this address
        address gov = router.governance();
        hevm.prank(gov);
        router.setGovernance(address(this));

        router.acceptGovernance();

        router.addStrategy(address(vault), address(mockStrategy));
    }

    function deposit(IYearn4626 _vault, uint256 _amount) public  {
        underlying.mint(address(this), _amount);

        underlying.approve(address(router), _amount);

        router.approve(underlying, address(_vault), _amount);

        router.depositToVault(_vault, _amount, address(this), _amount);
    }

    function allocateDebt(IYearn4626 _vault, MockStrategy _strategy, uint256 _amount) public {
        MockYearnV3(address(_vault)).updateDebt(address(_strategy), _amount);
    }

    function depositAndAllocateDebt(IYearn4626 _vault, MockStrategy _strategy, uint256 _amount) public {
        deposit(_vault, _amount);
        allocateDebt(_vault, _strategy, _amount);
        require(_strategy.totalAssets() == _amount);
    }

    function addStrategy(IYearn4626 _vault, MockStrategy _strategy) public {
        MockYearnV3(address(_vault)).addStrategy(address(_strategy));
        router.addStrategy(address(_vault), address(_strategy));
    }

    function createAndAddStrategy(IYearn4626 _vault) public returns (MockStrategy _strategy){
        _strategy = new MockStrategy(underlying);
        addStrategy(_vault, _strategy);
    }

    function testWithdraw(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        depositAndAllocateDebt(vault, mockStrategy, amount);

        vault.approve(address(router), amount);
        router.withdraw(vault, amount, address(this), amount);

        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == amount);
    }

    function testWithdrawWithPermit(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);

        uint256 privateKey = 0xBEEF;
        address owner = hevm.addr(privateKey);

        underlying.mint(address(this), amount);

        underlying.approve(address(router), amount);

        router.approve(underlying, address(vault), amount);

        router.depositToVault(vault, amount, owner);

        allocateDebt(vault, mockStrategy, amount);

        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    vault.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), amount, 0, block.timestamp))
                )
            )
        );

        vault.permit(owner, address(router), amount, block.timestamp, v, r, s);

        hevm.prank(owner);
        router.withdraw(vault, amount, owner, amount);

        require(vault.balanceOf(owner) == 0);
        require(underlying.balanceOf(owner) == amount);
    }

    function testWithdrawWithPermitViaMulticall(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        uint256 privateKey = 0xBEEF;
        address owner = hevm.addr(privateKey);

        underlying.mint(address(this), amount);

        underlying.approve(address(router), amount);

        router.approve(underlying, address(vault), amount);

        router.depositToVault(vault, amount, owner);

        allocateDebt(vault, mockStrategy, amount);

        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    vault.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), amount, 0, block.timestamp))
                )
            )
        );

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(SelfPermit.selfPermit.selector, vault, amount, block.timestamp, v, r, s);
        data[1] = abi.encodeWithSelector(IYearn4626RouterBase.withdraw.selector, vault, amount, owner, amount);

        hevm.prank(owner);
        router.multicall(data);

        require(vault.balanceOf(owner) == 0);
        require(underlying.balanceOf(owner) == amount);
    }

    function testFailWithdrawAboveMaxOut(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        depositAndAllocateDebt(vault, mockStrategy, amount);

        vault.approve(address(router), amount);
        router.withdraw(IYearn4626(address(vault)), amount, address(this), amount - 1);
    }

    function testRedeem(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        depositAndAllocateDebt(vault, mockStrategy, amount);

        vault.approve(address(router), amount);
        router.redeem(vault, amount, address(this), amount);

        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == amount);
    }

    function testRedeemTo(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        depositAndAllocateDebt(vault, mockStrategy, amount);

        router.approve(underlying, address(toVault), amount);

        require(vault.balanceOf(address(this)) == amount);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint256).max);

        router.migrate(vault, toVault, amount, address(this), amount);

        require(toVault.balanceOf(address(this)) == amount);
        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == 0);
    }

    function testRedeemToBelowMinOutReverts(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0 && amount != type(uint128).max);
        depositAndAllocateDebt(vault, mockStrategy, amount);

        router.approve(underlying, address(toVault), amount);

        require(vault.balanceOf(address(this)) == amount);
        require(underlying.balanceOf(address(this)) == 0);

        vault.approve(address(router), type(uint256).max);

        hevm.expectRevert(abi.encodeWithSignature("MinSharesError()"));
        router.migrate(vault, toVault, amount, address(this), amount + 1);
    }

    function testRedeemMax(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        depositAndAllocateDebt(vault, mockStrategy, amount);

        vault.approve(address(router), amount);
        router.redeem(vault);

        require(vault.balanceOf(address(this)) == 0);
        require(underlying.balanceOf(address(this)) == amount);
    }

    function testRedeemWithPermit(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        uint256 privateKey = 0xBEEF;
        address owner = hevm.addr(privateKey);

        underlying.mint(address(this), amount);

        underlying.approve(address(router), amount);

        router.approve(underlying, address(vault), amount);

        router.depositToVault(vault, amount, owner);

        allocateDebt(vault, mockStrategy, amount);

        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    vault.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), amount, 0, block.timestamp))
                )
            )
        );

        vault.permit(owner, address(router), amount, block.timestamp, v, r, s);

        hevm.prank(owner);
        router.redeem(vault, amount, owner, amount);

        require(vault.balanceOf(owner) == 0);
        require(underlying.balanceOf(owner) == amount);
    }

    function testRedeemWithPermitViaMulticall(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        uint256 privateKey = 0xBEEF;
        address owner = hevm.addr(privateKey);

        underlying.mint(address(this), amount);

        underlying.approve(address(router), amount);

        router.approve(underlying, address(vault), amount);

        router.depositToVault(vault, amount, owner);

        allocateDebt(vault, mockStrategy, amount);

        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    vault.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(router), amount, 0, block.timestamp))
                )
            )
        );

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(SelfPermit.selfPermit.selector, vault, amount, block.timestamp, v, r, s);
        data[1] = abi.encodeWithSelector(IYearn4626RouterBase.redeem.selector, vault, amount, owner, amount);

        hevm.prank(owner);
        router.multicall(data);

        require(vault.balanceOf(owner) == 0);
        require(underlying.balanceOf(owner) == amount);
    }

    function testRedeemBelowMinOutReverts(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0 && amount != type(uint128).max);
        depositAndAllocateDebt(vault, mockStrategy, amount);

        vault.approve(address(router), amount);

        hevm.expectRevert(abi.encodeWithSignature("MinAmountError()"));
        router.redeem(IYearn4626(address(vault)), amount, address(this), amount + 1);
    }

    //// NO STRATEGIES ADDED TO WITHDRAWAL STACK \\\\

    function testFailWithdrawNoStack(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        depositAndAllocateDebt(vault, mockStrategy, amount);

        router.removeStrategy(address(vault), address(mockStrategy));

        vault.approve(address(router), amount);
        router.withdraw(vault, amount, address(this), amount);
    }

    function testFailRedeemNoStack(uint128 amount) public {
        Assume(address(hevm)).assume(amount != 0);
        depositAndAllocateDebt(vault, mockStrategy, amount);

        router.removeStrategy(address(vault), address(mockStrategy));

        vault.approve(address(router), amount);
        router.redeem(vault, amount, address(this), amount);
    }

    //// MULTIPLE STRATEGIES IN THE STACK \\\\

    function testRedeemLargeStack(uint128 amount) public {
        Assume(address(hevm)).assume(amount > 2);
        depositAndAllocateDebt(vault, mockStrategy, amount / 2);

        MockStrategy _strategy2 = createAndAddStrategy(vault);
        depositAndAllocateDebt(vault, _strategy2, amount / 2);
        
        vault.approve(address(router), amount);
        router.redeem(vault);
    }

}