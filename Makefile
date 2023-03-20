# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# deps
update:; forge update

build  :; forge build
# local tests without fork
test  :; forge test
trace  :; forge test -vvv
test-gas  :; forge test --gas-report
test-contract  :; forge test --match-contract $(contract)
trace-contract  :; forge test -vvv --match-contract $(contract)
test-test  :; forge test --match-test $(test)
trace-test  :; forge test --match-test $(test)
clean  :; forge clean
snapshot :; forge snapshot