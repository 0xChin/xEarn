export function shortenAddress(address) {
  if (!address || address.length < 10) {
    return address;
  }
  const start = address.slice(0, 6);
  const end = address.slice(-4);
  return `${start}...${end}`;
}

export function transformSymbol(symbol) {
  if (symbol === "crv3crypto") {
    return "Curve Tricrypto";
  }
  if (symbol === "MIM3CRV-f") {
    return "Curve MIM 3Pool";
  }
  return symbol;
}

export function numberWithCommas(x) {
  return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
