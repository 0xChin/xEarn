import "../styles/globals.css";
import { WagmiConfig, createClient, configureChains } from "wagmi";
import { alchemyProvider } from "wagmi/providers/alchemy";
import { polygon } from "wagmi/chains";
import { getDefaultProvider } from "ethers";
import { InjectedConnector } from "wagmi/connectors/injected";

const { chains, provider } = configureChains(
  [polygon],
  [alchemyProvider({ apiKey: "8PgxDIFbDGHkj3LUZCJVXOYBkQL3aXb8" })]
);

const client = createClient({
  autoConnect: true,
  connectors: [new InjectedConnector({ chains })],
  provider,
});

function MyApp({ Component, pageProps }) {
  return (
    <WagmiConfig client={client}>
      <Component {...pageProps} />
    </WagmiConfig>
  );
}

export default MyApp;
