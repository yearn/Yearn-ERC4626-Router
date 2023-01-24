pragma solidity 0.8.10;

import {ERC20, MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";

import {MockYearn4626} from "./mocks/MockYearn4626.sol";
import {WETH} from "solmate/tokens/WETH.sol";

import {IYearn4626Router, Yearn4626Router} from "../Yearn4626Router.sol";
import {IYearn4626RouterBase, Yearn4626RouterBase, IWETH9, IYearn4626, SelfPermit, PeripheryPayments} from "../Yearn4626RouterBase.sol";

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {console} from "./utils/Console.sol";

interface Assume {
    function assume(bool) external;
}

contract WithdrawalStackTest is DSTestPlus {
    MockERC20 underlying;
    IYearn4626 vault;
    IYearn4626 toVault;
    Yearn4626Router router;
    IWETH9 weth;
    IYearn4626 wethVault;

    bytes32 public PERMITTYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    receive() external payable {}

    function createVault() public returns (IYearn4626 newVault) {
        MockERC20 asset = new MockERC20("Mock Token", "TKN", 18);
        newVault = IYearn4626(address(new MockYearn4626(asset)));
    }

    function createStrategy(IYearn4626 _vault) public returns (address strategy) {
        strategy = address(new MockERC4626(ERC20(_vault.asset()), "Mock Strategy", "mSTGY"));
    }

    function addStrategyToVault(IYearn4626 _vault, address strategy) public {
        MockYearn4626 vault_ = MockYearn4626(address(_vault));
        vault_.addStrategy(strategy);
    }

    function removeStrategyFromVault(IYearn4626 _vault, address strategy) public {
        MockYearn4626 vault_ = MockYearn4626(address(_vault));
        vault_.removeStrategy(strategy);
    }

    function createStrategyAndAddToVault(IYearn4626 _vault) public returns (address strategy) {
        strategy = createStrategy(_vault);
        addStrategyToVault(_vault, strategy);
    }

    function addStrategyToRouter(IYearn4626 _vault, address strategy) public {
        router.addStrategy(address(_vault), strategy);
    }

    function removeStrategyFromRouter(IYearn4626 _vault, address strategy) public {
        router.removeStrategy(address(_vault), strategy);
    }

    function addStrategyToVaultAndRouter(IYearn4626 _vault, address strategy) public {
        addStrategyToVault(_vault, strategy);
        addStrategyToRouter(_vault, strategy);
    }

    function createStrategyAndAddToVaultAndRouter(IYearn4626 _vault) public returns (address strategy) {
        strategy = createStrategy(_vault);
        addStrategyToVaultAndRouter(_vault, strategy);
    }

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        vault = IYearn4626(address(new MockYearn4626(underlying)));
        toVault = IYearn4626(address(new MockYearn4626(underlying)));

        weth = IWETH9(address(new WETH()));

        wethVault = IYearn4626(address(new MockYearn4626(weth)));

        router = new Yearn4626Router("", weth); // empty reverse ens

        address gov = router.governance();
        hevm.prank(gov);
        router.setGovernance(address(this));

        router.acceptGovernance();
    }

    function testAddStrategy() public {
        address strategy = createStrategyAndAddToVault(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        addStrategyToRouter(vault, strategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy, "1");

        address secondStrategy = createStrategyAndAddToVault(vault);

        addStrategyToRouter(vault, secondStrategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 2);
        assertEq(router.withdrawalStack(address(vault), 0), strategy, "2");
        assertEq(router.withdrawalStack(address(vault), 1), secondStrategy, "3");
    }

    function testRemoveStrategy() public {
        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        router.removeStrategy(address(vault), strategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 0, "2");
    }

    function testStrategiesArrayLength() public {
        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);

        address secondStrategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 2);

        removeStrategyFromRouter(vault, strategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);

        removeStrategyFromRouter(vault, secondStrategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 0);
    }

    function testAddStrategyNotAddedTo_vaultFails() public {
        address strategy = createStrategy(vault);

        hevm.expectRevert(abi.encodeWithSignature("NotActive()"));
        addStrategyToRouter(vault, strategy);
    }

    function testAddStrategyNotGovFails() public {
        address strategy = createStrategy(vault);

        hevm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        hevm.prank(address(1));
        router.addStrategy(address(vault), strategy);
    }

    function testAddStrategyStackFullFails() public {
        address strategy;

        for (uint256 i; i < 10; ++i) {
            strategy = createStrategy(vault);
            addStrategyToVault(vault, strategy);
            router.addStrategy(address(vault), strategy);
        }

        assertEq(router.getWithdrawalStack(address(vault)).length, 10);

        strategy = createStrategy(vault);
        addStrategyToVault(vault, strategy);

        hevm.expectRevert(abi.encodeWithSignature("StackSize()"));
        router.addStrategy(address(vault), strategy);
    }

    function testRemoveStrategyMultipleStrategies() public {
        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        address secondStrategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 2);
        assertEq(router.withdrawalStack(address(vault), 1), secondStrategy);

        address thirdStrategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 3);
        assertEq(router.withdrawalStack(address(vault), 2), thirdStrategy);

        router.removeStrategy(address(vault), strategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 2);
        assertEq(router.withdrawalStack(address(vault), 0), secondStrategy);
        assertEq(router.withdrawalStack(address(vault), 1), thirdStrategy);

        router.removeStrategy(address(vault), thirdStrategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), secondStrategy);

        router.removeStrategy(address(vault), secondStrategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 0);
    }

    function testRemoveStrategyNotGovFails() public {
        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        hevm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        hevm.prank(address(1));
        removeStrategyFromRouter(vault, strategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
    }

    function testFailRemoveStrategyNotAddedFails() public {
        address strategy = createStrategy(vault);

        hevm.expectRevert(abi.encodeWithSignature(""));
        removeStrategyFromRouter(vault, strategy);

        addStrategyToRouter(vault, strategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        address secondStrategy = createStrategy(vault);

        router.removeStrategy(address(vault), secondStrategy);
    }

    function testSetNewStack() public {
        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        address secondStrategy = createStrategyAndAddToVault(vault);
        address[] memory stack = new address[](1);
        stack[0] = secondStrategy;

        router.setWithdrawalStack(address(vault), stack);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), secondStrategy);

        address thirdStrategy = createStrategyAndAddToVault(vault);
        address fourthStrategy = createStrategyAndAddToVault(vault);

        address[] memory secondStack = new address[](4);
        secondStack[0] = strategy;
        secondStack[1] = secondStrategy;
        secondStack[2] = thirdStrategy;
        secondStack[3] = fourthStrategy;
        router.setWithdrawalStack(address(vault), secondStack);

        assertEq(router.getWithdrawalStack(address(vault)).length, 4);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);
        assertEq(router.withdrawalStack(address(vault), 1), secondStrategy);
        assertEq(router.withdrawalStack(address(vault), 2), thirdStrategy);
        assertEq(router.withdrawalStack(address(vault), 3), fourthStrategy);

        address[] memory emptyStack = new address[](0);

        router.setWithdrawalStack(address(vault), emptyStack);

        assertEq(router.getWithdrawalStack(address(vault)).length, 0);
    }

    function testSetNewStackNotGovFails() public {
        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        address secondStrategy = createStrategyAndAddToVault(vault);
        address[] memory stack = new address[](1);
        stack[0] = secondStrategy;

        hevm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        hevm.prank(address(1));
        router.setWithdrawalStack(address(vault), stack);
    }

    function testSetNewStackMoreThanMaxFails() public {
        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        address[] memory badStack = new address[](11);

        for (uint256 i; i < 11; ++i) {
            badStack[i] = createStrategyAndAddToVault(vault);
        }

        hevm.expectRevert(abi.encodeWithSignature("StackSize()"));
        router.setWithdrawalStack(address(vault), badStack);
    }

    function testReplaceIndex() public {
        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        address secondStrategy = createStrategyAndAddToVault(vault);

        router.replaceWithdrawalStackIndex(address(vault), 0, secondStrategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), secondStrategy);

        // fill the whole stack with new strategies
        for (uint256 i; i < 9; ++i) {
            createStrategyAndAddToVaultAndRouter(vault);
        }

        assertEq(router.getWithdrawalStack(address(vault)).length, 10);

        address newStrategy = createStrategyAndAddToVault(vault);

        router.replaceWithdrawalStackIndex(address(vault), 4, newStrategy);

        assertEq(router.getWithdrawalStack(address(vault)).length, 10);
        assertEq(router.withdrawalStack(address(vault), 4), newStrategy);
    }

    function testReplaceIndexNotGovFails() public {
        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        address secondStrategy = createStrategyAndAddToVault(vault);

        hevm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        hevm.prank(address(1));
        router.replaceWithdrawalStackIndex(address(vault), 0, secondStrategy);

        // fill the whole stack with new strategies
        for (uint256 i; i < 9; ++i) {
            createStrategyAndAddToVaultAndRouter(vault);
        }

        assertEq(router.getWithdrawalStack(address(vault)).length, 10);

        address newStrategy = createStrategyAndAddToVault(vault);

        hevm.expectRevert(abi.encodeWithSignature("NotAuthorized()"));
        hevm.prank(address(1));
        router.replaceWithdrawalStackIndex(address(vault), 4, newStrategy);
    }

    function testReplaceIndexSameStrategyFails() public {
        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        hevm.expectRevert(bytes("same strategy"));
        router.replaceWithdrawalStackIndex(address(vault), 0, strategy);
    }

    function testReplaceIndexInactiveStrategyFails() public {
        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        address secondStrategy = createStrategy(vault);

        hevm.expectRevert(abi.encodeWithSignature("NotActive()"));
        router.replaceWithdrawalStackIndex(address(vault), 0, secondStrategy);
    }

    function testFailReplaceIndexInvalidIndex() public {
        assertEq(router.getWithdrawalStack(address(vault)).length, 0);

        address strategy = createStrategyAndAddToVaultAndRouter(vault);

        assertEq(router.getWithdrawalStack(address(vault)).length, 1);
        assertEq(router.withdrawalStack(address(vault), 0), strategy);

        address secondStrategy = createStrategyAndAddToVault(vault);

        //hevm.expectRevert(bytes("Index out of bounds"));
        router.replaceWithdrawalStackIndex(address(vault), 4, secondStrategy);
    }
}
