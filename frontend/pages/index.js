import Head from "next/head";
import styles from "../styles/Home.module.css";
import {
  useAccount,
  useConnect,
  useContractWrite,
  useDisconnect,
  useNetwork,
  usePrepareContractWrite,
  useSigner,
  useSwitchNetwork,
} from "wagmi";
import { InjectedConnector } from "wagmi/connectors/injected";
import { useEffect, useState } from "react";
import {
  shortenAddress,
  transformSymbol,
  numberWithCommas,
} from "../utils/utils";
import { ethers } from "ethers";
import XEARN_ABI from "../utils/abi/xEarn.json";
import VAULT_MANAGER_ABI from "../utils/abi/VaultManager.json";
import WETH_ABI from "../utils/abi/Weth.json";

export default function Home({ vaults }) {
  const [depositMode, setDepositMode] = useState(false);
  const [selectedVaults, setSelectedVaults] = useState({});
  const [mounted, setMounted] = useState(false);
  const { data: signer } = useSigner();
  const { address, isConnected } = useAccount();
  const { connect } = useConnect({
    connector: new InjectedConnector(),
  });
  const { disconnect } = useDisconnect();
  const { chain } = useNetwork();
  const { switchNetwork } = useSwitchNetwork();
  const [depositedAmounts, setDepositedAmounts] = useState({});

  const depositedAmount = numberWithCommas(
    vaults
      .reduce(
        (total, vault) =>
          total +
          (depositedAmounts[vault.address]?.amount
            ? parseFloat(depositedAmounts[vault.address]?.amount) * vault.price
            : 0),
        0
      )
      .toFixed(2)
  );

  const OPTIMISM_VAULT_MANAGER = "0x30bb5A1858D1CfE22AF5E028F15dD8450E76FDc3";
  const ARBITRUM_VAULT_MANAGER = "0x305c0C5001f40D8fa21740d1D135Cdbb7Fd97C53";
  const XEARN = "0xed6229CD962413CbcF07C8f9DD8D30607157Fff7";
  const WETH = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";

  const ARBITRUM_NODE_URI =
    "https://arb-mainnet.g.alchemy.com/v2/M4OMAtif3ZSHXjiTa0AT-lb_iKA0Lj3o"; // Plz don't use the api key
  const OPTIMISM_NODE_URI =
    "https://opt-mainnet.g.alchemy.com/v2/xhj3Bj3ukhHn3wUtCt76Bby0AmsUnmWp"; // Plz don't use the api key

  const xEarnContract = new ethers.Contract(XEARN, XEARN_ABI, signer);
  const wethContract = new ethers.Contract(WETH, WETH_ABI, signer);

  const arbitrumVaultManager = new ethers.Contract(
    ARBITRUM_VAULT_MANAGER,
    VAULT_MANAGER_ABI,
    new ethers.providers.JsonRpcProvider(ARBITRUM_NODE_URI)
  );

  const optimismVaultManager = new ethers.Contract(
    OPTIMISM_VAULT_MANAGER,
    VAULT_MANAGER_ABI,
    new ethers.providers.JsonRpcProvider(OPTIMISM_NODE_URI)
  );

  async function getShares(userAddress, vaultAddress, contractInstance) {
    return (
      await contractInstance.shares(userAddress, vaultAddress)
    ).toString();
  }

  async function fetchDepositedAmounts() {
    const amounts = {};

    for (const vault of vaults) {
      const contractInstance =
        vault.chainId === 10 ? optimismVaultManager : arbitrumVaultManager;
      const shares = await getShares(address, vault.address, contractInstance);
      amounts[vault.address] = {
        amount: shares / 10 ** vault.decimals,
        chainId: vault.chainId,
      };

      setDepositedAmounts(amounts);
    }
  }

  // Move hooks outside of the approve function
  const { config: approveConfig } = usePrepareContractWrite({
    address: WETH,
    abi: WETH_ABI,
    functionName: "approve",
    args: [XEARN, ethers.constants.MaxUint256],
  });

  const {
    data: approveData,
    isLoading: approveIsLoading,
    isSuccess: approveIsSuccess,
    write,
  } = useContractWrite(approveConfig);

  // Update the approve function
  function approve() {
    write?.();
  }

  function confirmDeposit() {
    const selectedVaultsArray = Object.entries(selectedVaults);

    // Build an array of structs for depositArgs
    const depositArgs = selectedVaultsArray.map(
      ([address, { amount, chainId }]) => ({
        target:
          chainId === 10 ? OPTIMISM_VAULT_MANAGER : ARBITRUM_VAULT_MANAGER,
        vault: address,
        curvePool:
          chainId === 10
            ? ethers.constants.AddressZero
            : "0x960ea3e3C7FB317332d990873d354E18d7645590",
        destinationDomain: chainId === 10 ? 1869640809 : 1634886255,
        poolFee: 3000,
        amount: ethers.utils.parseEther(amount),
        relayerFee: ethers.utils.parseEther("1"),
      })
    );

    console.log(depositArgs);

    if (selectedVaultsArray.length === 1) {
      xEarnContract.deposit(depositArgs[0], {
        value: ethers.utils.parseEther("1"),
      });
    } else {
      xEarnContract.multiDeposit(depositArgs, {
        value: ethers.utils.parseEther("1").mul(depositArgs.length),
      });
    }
  }

  function withdrawAll() {
    const depositedAmountsArray = Object.entries(depositedAmounts);

    const depositedAmountsArrayFiltered = depositedAmountsArray.filter(
      ([_, { amount }]) => amount !== 0
    );

    // Build an array of structs for depositArgs
    const withdrawArgs = depositedAmountsArrayFiltered.map(
      ([address, { _, chainId }]) => {
        return {
          target:
            chainId === 10 ? OPTIMISM_VAULT_MANAGER : ARBITRUM_VAULT_MANAGER,
          vault: address,
          curvePool:
            chainId === 10
              ? ethers.constants.AddressZero
              : "0x960ea3e3C7FB317332d990873d354E18d7645590",
          destinationDomain: chainId === 10 ? 1869640809 : 1634886255,
          poolFee: 3000,
          amount: 0,
          relayerFee: ethers.utils.parseEther("1"),
          xRelayerFee: ethers.utils.parseEther("0.00004"),
        };
      }
    );

    xEarnContract.multiWithdraw(withdrawArgs, {
      value: ethers.utils.parseEther("1").mul(withdrawArgs.length),
    });
  }

  function toggleVault(vaultAddress) {
    setSelectedVaults((prevSelectedVaults) => {
      if (prevSelectedVaults[vaultAddress]) {
        const updatedVaults = { ...prevSelectedVaults };
        delete updatedVaults[vaultAddress];
        return updatedVaults;
      } else {
        return {
          ...prevSelectedVaults,
          [vaultAddress]: {
            amount: prevSelectedVaults[vaultAddress] || "0",
            chainId: vaults.find((vault) => vault.address === vaultAddress)
              ?.chainId,
          },
        };
      }
    });
  }

  function updateDepositAmount(vaultAddress, amount) {
    setSelectedVaults((prevSelectedVaults) => {
      return {
        ...prevSelectedVaults,
        [vaultAddress]: {
          amount,
          chainId: vaults.find((vault) => vault.address === vaultAddress)
            ?.chainId,
        },
      };
    });
  }

  useEffect(() => {
    if (chain && chain.id !== 137) {
      switchNetwork(137);
    }
  }, [chain]);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (isConnected && address) {
      fetchDepositedAmounts();
    }
  }, [isConnected, address]);

  useEffect(() => {
    console.log(depositedAmounts);
  }, [depositedAmounts]);

  return (
    <div className={styles.container}>
      <Head>
        <title>xEarn</title>
        <meta name="description" content="Generated by create next app" />
        <link rel="icon" href="/favicon.ico" />
        <link
          rel="apple-touch-icon"
          sizes="180x180"
          href="/apple-touch-icon.png"
        />
        <link
          rel="icon"
          type="image/png"
          sizes="32x32"
          href="/favicon-32x32.png"
        />
        <link
          rel="icon"
          type="image/png"
          sizes="16x16"
          href="/favicon-16x16.png"
        />
        <link rel="manifest" href="/site.webmanifest" />
        <link rel="mask-icon" href="/safari-pinned-tab.svg" color="#5bbad5" />
        <meta name="msapplication-TileColor" content="#00aba9" />
        <meta name="theme-color" content="#ffffff"></meta>
      </Head>

      <p className={styles.warning}>
        Warning! This project is an experiment, it's not audited and DEFINITELY
        has vulnerabilities. If you want to deposit in any vault you see, go to{" "}
        <a
          href="https://yearn.finance/vaults"
          target="_blank"
          className={styles.yearn}
        >
          Yearn Finance
        </a>
      </p>

      <header className={styles.header}>
        <img
          src="/logo.png"
          alt="Logo"
          width="50"
          className={styles.logoHeader}
        />
        {mounted && isConnected ? (
          <span onClick={disconnect} className={styles.address}>
            {shortenAddress(address)}
          </span>
        ) : (
          <button className={styles.btn} onClick={connect}>
            Connect wallet
          </button>
        )}
      </header>

      <main className={styles.main}>
        <div className={styles.balances}>
          <div className={styles.deposited}>
            <p className={styles.balanceText}>Deposited</p>
            <b className={styles.balanceAmount}>${depositedAmount}</b>
          </div>
          <div className={styles.earnings}>
            <p className={styles.balanceText}>Earnings</p>
            <b className={styles.balanceAmount}>$0,00</b>
          </div>
        </div>

        <button
          className={`${styles.btn} ${styles.approveBtn}`}
          onClick={approve}
        >
          {approveIsSuccess
            ? "WETH Approved"
            : approveIsLoading
            ? "Approving..."
            : "Approve WETH"}
        </button>

        <div className={styles.vaults}>
          <h2 className={styles.vaultsText}>All Vaults</h2>
          <div className={styles.actions}>
            <div>
              <button
                className={`${styles.btn} ${styles.actionBtn}`}
                onClick={() => setDepositMode(!depositMode)}
              >
                {depositMode ? "Cancel" : "Deposit"}
              </button>
              {Object.keys(selectedVaults).length > 0 && (
                <button
                  className={`${styles.btn} ${styles.actionBtn}`}
                  onClick={confirmDeposit}
                >
                  Confirm deposit
                </button>
              )}
            </div>
            <div>
              <button
                className={`${styles.btn} ${styles.actionBtn}`}
                onClick={withdrawAll}
              >
                Withdraw all
              </button>
            </div>
          </div>
          <table className={styles.table}>
            <thead>
              <tr>
                {depositMode && <th>Select</th>}
                <th>Token</th>
                <th>APY</th>
                <th>Deposited</th>
                <th>TVL</th>
                {depositMode && <th>{"Amount (WETH)"}</th>}
              </tr>
            </thead>
            <tbody>
              {vaults.map((row, index) => (
                <tr key={index}>
                  {depositMode && (
                    <td>
                      <input
                        type="checkbox"
                        onChange={() => toggleVault(row.address)}
                        checked={selectedVaults[row.address] !== undefined}
                        className={styles.checkbox}
                        id={`checkbox-${index}`}
                      />
                    </td>
                  )}
                  <td width="50%" className={styles.tokenRow}>
                    <img src={row.icon} alt={row.token} width="40px" />{" "}
                    <p className={styles.tokenText}>
                      {transformSymbol(row.token)}
                    </p>
                  </td>
                  <td>{row.apy}%</td>
                  <td
                    className={
                      depositedAmounts[row.address]?.amount &&
                      parseFloat(depositedAmounts[row.address]?.amount) > 0
                        ? ""
                        : styles.depositZero
                    }
                  >
                    {depositedAmounts[row.address]?.amount
                      ? parseFloat(
                          depositedAmounts[row.address]?.amount
                        ).toFixed(4)
                      : "0.00"}
                  </td>
                  <td>${numberWithCommas(row.tvl)}</td>
                  {depositMode && (
                    <td>
                      <input
                        type="number"
                        min="0"
                        step="any"
                        placeholder="WETH Amount"
                        className={styles.input}
                        value={selectedVaults[row.address]?.amount || ""}
                        onChange={(e) =>
                          updateDepositAmount(row.address, e.target.value)
                        }
                      />
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </main>

      <footer className={styles.footer}>
        <a
          href="https://twitter.com/chiin_rock"
          target="_blank"
          rel="noopener noreferrer"
        >
          Made with ✖ by Chiin
        </a>
      </footer>
    </div>
  );
}

export async function getStaticProps() {
  const endpoints = [
    "https://api.yearn.finance/v1/chains/10/vaults/all",
    "https://api.yearn.finance/v1/chains/42161/vaults/all",
  ];

  const responses = await Promise.all(endpoints.map((url) => fetch(url)));
  const [data1, data2] = await Promise.all(responses.map((res) => res.json()));
  const combinedData = [
    ...data1.map((vault) => ({ ...vault, chainId: 10 })),
    ...data2.map((vault) => ({ ...vault, chainId: 42161 })),
  ];

  const vaults = combinedData
    .map((vault) => ({
      address: vault.address,
      token: vault.token.symbol,
      icon: vault.token.icon,
      decimals: vault.token.decimals,
      apy: (vault.apy.net_apy * 100).toFixed(2),
      price: vault.tvl.price,
      tvl: vault.tvl.tvl.toFixed(0),
      chainId: vault.chainId,
    }))
    .filter((vault) => parseFloat(vault.tvl) > 0);

  const uniqueVaults = vaults.reduce((acc, vault) => {
    const existingVault = acc.find((v) => v.token === vault.token);

    if (existingVault) {
      if (parseFloat(vault.tvl) > parseFloat(existingVault.tvl)) {
        const index = acc.indexOf(existingVault);
        acc[index] = vault;
      }
    } else {
      acc.push(vault);
    }

    return acc;
  }, []);

  uniqueVaults.sort((a, b) => parseFloat(b.apy) - parseFloat(a.apy));

  return {
    props: {
      vaults: uniqueVaults,
    },
  };
}
