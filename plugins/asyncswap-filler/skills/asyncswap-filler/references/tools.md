# Async Swap agent filler tools

Callable TypeScript functions and a JSON CLI for discovering, evaluating, and
preparing fills. The repository skill is
[asyncswap-filler](../SKILL.md).
An AI agent selects candidates and explains results; deterministic code checks
order identity, live amounts, fees, configured limits, and calldata.

This first version supports the current salt-based contracts and approved
asset/USDC pools. Legacy nonce-only orders are listed but cannot be evaluated or
prepared. It has no signer, continuous loop, model dependency, or market quote
integration. A future bot can reuse `FillerTools` with a quote adapter and a
separately authorized execution service.

## Configure

Set `ASYNCSWAP_FILLER_ROOT` to the absolute path of a checkout containing `packages/filler-tools`, with Bun dependencies installed. Alternatively, save that path as one line in `${XDG_CONFIG_HOME:-$HOME/.config}/asyncswap/filler-root`; the launcher reads this fallback as text, never as executable shell. Set `FILLER_SKILL_DIR` to the directory containing this skill. The launcher works from any working directory. This CLI is not currently published as an installable package.
Create an operator-controlled JSON file with these fields. Addresses below are
placeholders: verify the chain, USDC, hook, and corresponding router deployment
before using them. Token symbols and API metadata are not deployment authority.

```json
{
  "apiBase": "http://localhost:42070",
  "rpcUrl": "http://localhost:8545",
  "chainId": 130,
  "router": "<verified router address>",
  "hook": "<verified salt-based hook address>",
  "usdc": "<approved USDC address on this chain>",
  "filler": "<wallet address, no private key>",
  "allowedTokens": ["<USDC address>", "<asset address>"],
  "maxPayment": "1000000000",
  "maxSpendUsdc": "1005000000",
  "minProfitUsdc": "1000000",
  "maxQuoteAgeSeconds": 30,
  "maxBlockAgeSeconds": 60
}
```

All amount fields are unsigned decimal strings. USDC amounts use six decimals;
`minProfitUsdc: "1000000"` means 1 USDC. `maxPayment` is a separate cap in the
**payment token's smallest units**, including the protocol fee. Select this cap
for the intended payment asset; it is not a universal USDC value limit.
`maxSpendUsdc` includes payment valuation and all supplied execution costs.
Allow the zero address only when native currency is an intended pool asset.
The tools check USDC decimals, but configuration remains responsible for token
authenticity and the router/hook pairing.

Do not source configuration from order metadata or allow a model to increase
operator limits to make a candidate pass. Keep provider credentials out of
version control. No private keys are accepted or required.

## Call tools

Each command reads a config file and a request JSON file, prints JSON, and exits.
Amounts in results remain decimal strings. Failures exit with status 1.

```sh
bash "$FILLER_SKILL_DIR/scripts/filler.sh" --help
bash "$FILLER_SKILL_DIR/scripts/filler.sh" discover /path/config.json /path/request.json
bash "$FILLER_SKILL_DIR/scripts/filler.sh" evaluate /path/config.json /path/request.json
bash "$FILLER_SKILL_DIR/scripts/filler.sh" prepare /path/config.json /path/request.json
bash "$FILLER_SKILL_DIR/scripts/filler.sh" prepare-bundle /path/config.json /path/request.json
```

| Tool | Request | Result |
| --- | --- | --- |
| `discover` | `{"limit":50}`; optional `cursor` | Unverified open candidates and `nextCursor`. Follow one page at a time until null; stop if a cursor repeats. |
| `evaluate` | `{"orderId":"0x…"}` | Verified live quantities, protocol fee, and block reference; `valuationStatus: "required"`. |
| `evaluate` | `{"orderId":"0x…","valuation":{…}}` | Same checks plus a supplied USDC profit estimate and policy result. |
| `prepare` | `{"orderId":"0x…","valuation":{…}}` | Fresh evaluation, then the next approval or a simulated fill transaction. |
| `prepare-bundle` | `{"orderId":"0x…","valuation":{…},"window":{"seconds":5}}` | Unichain-only fill plan with a quote-bounded timestamp window; optional externally supplied `signedTransaction` produces an RPC request. |

For programmatic use, import `FillerTools`, `parseConfig`, and `json` from
`packages/filler-tools/src/index.ts` in the application checkout, pass a Viem public client on the configured chain, and call the
same methods (`prepareBundle` for bundle preparation). `parseConfig` must validate external configuration first.
The package reuses the app's current signed-order ABI and identity helpers so
contract tuple encoding stays consistent.

## Supply a valuation

First call `evaluate` without a valuation to obtain the exact received and paid
assets and amounts. A trusted quote adapter or user-provided valuation then
supplies the following object. Do not invent quotes, prices, timestamps, or
transaction cost estimates with an LLM.

```json
{
  "chainId": 130,
  "orderId": "<evaluated order ID>",
  "receiveToken": "<maker input token address>",
  "payToken": "<maker output token address>",
  "receiveAmount": "<exact raw amount from evaluate>",
  "payAmount": "<exact gross amount from evaluate, including protocol fee>",
  "usdc": "<configured USDC address>",
  "observedAt": 0,
  "expiresAt": 0,
  "source": "<quote provider and reference>",
  "proceedsUsdc": "1010000000",
  "paymentUsdc": "1000000000",
  "costsUsdc": "2000000"
}
```

Replace timestamps with actual Unix seconds. Value the exact received amount
using conservative net liquidation proceeds and the exact paid amount using its
acquisition cost. When either leg is USDC, its valuation must equal its raw
quantity. Include approval, fill, and hedge gas, spreads and other execution
costs in `costsUsdc` unless already included in the leg quotes; avoid double
counting. The protocol fee is already included in `payAmount`.

`estimatedProfitUsdc = proceedsUsdc - paymentUsdc - costsUsdc`.

The tool validates quote binding and freshness, **not provider authenticity or
the completeness of supplied costs**. This is a supplied valuation estimate,
not a guaranteed profit or an executable hedge. The fill simulation returns
estimated gas in native units; compare it with the valuation's cost allowance
and refresh the valuation if necessary. A production bot needs an authenticated
quote adapter and an execution-cost model before automated eligibility decisions.

## Interpret preparation

- `approval_required`: only the next ERC-20 approval is returned. A nonzero
  insufficient allowance produces a zero-reset first, then a fresh call prepares
  the exact gross approval. No fill has been simulated. Obtain approval for the
  specific transaction, wait for its receipt, and call `prepare` again.
- `simulated`: an `eth_call` and gas estimate succeeded from the configured
  filler at the returned block. The transaction caps the total payment at the
  evaluated gross amount. No transaction was signed or broadcast.

Re-prepare immediately before wallet submission and inspect any changed terms.
Simulation does not reserve an order: another filler, maker repricing,
cancellation, a reorg, or gas changes can invalidate the result. After an
authorized submission, wait for a successful receipt and re-read order state.
Do not claim completion from a preparation response.

The first version returns unsigned approvals without simulating them. The wallet
must preflight the exact approval; tokens with unusual approval behavior may
still fail. Live signing authorization is outside this package.

## Prepare a Unichain bundle

The adapter uses `@asyncswap/jsonrpc@0.4.16` from
[eth-libs](https://github.com/asyncswap/eth-libs) to build the JSON-RPC request.
It has a separate Unichain method schema: Ethereum Flashbots fields such as
`blockNumber`, `builders`, or `replacementUuid` are not added to the request.

Use chain ID 130 and the same configured fill policy. Request:

```json
{
  "orderId": "<order ID>",
  "valuation": { "...": "the complete fresh valuation described above" },
  "window": { "seconds": 5 }
}
```

`window` is optional; its default is five seconds, with a supported range of
1–30 seconds. The window starts after preflight and ends no later than one
second before the quote's exclusive expiry. Quotes with too little remaining
lifetime are rejected. This adapter uses timestamp ranges only.

- `approval_required`: the next approval/reset remains separate, with no bundle.
  Confirm it through the authorized wallet workflow and prepare again.
- `bundle_signature_required`: the fill passed transaction simulation. The result
  contains an unsigned transaction and bundle window; `rpcRequest` is null.
  The wallet still needs to set nonce, gas and fee limits and sign the fill.
- `bundle_request_prepared`: supply an externally signed EIP-1559 transaction as
  `signedTransaction` in a fresh `prepare-bundle` call. The tool verifies chain,
  recovered signer, router, calldata, value, and pending nonce. It repeats the
  call simulation using the signed gas/fees/access list and checks native funds
  against the maximum execution gas charge. It then builds an `eth_sendBundle`
  JSON-RPC object containing exactly that one signed transaction. Nothing is sent.

The generated request targets `https://mainnet.unichain.org`, includes only
`txs`, `minTimestamp`, and `maxTimestamp`, and omits `revertingTxHashes` to retain
revert protection. No automatic retries, public-mempool fallback, or cancellation
are implemented. The caller must refresh the valuation and preparation if the
window expires; do not extend an old request's timestamps.

These choices follow the current [Unichain bundle documentation](https://developers.uniswap.org/docs/unichain/technical-information/advanced-txn):
one transaction per bundle, mutually exclusive block/timestamp ranges, and no
bundle cancellation. A separate approval or hedge cannot be appended. The window
belongs to the RPC envelope, not the signed transaction; it does not prevent
someone holding those signed bytes from broadcasting them through another path.

`bundle.simulation` is explicitly `transaction_eth_call_only`. It is not a relay
bundle simulation, acceptance, inclusion guarantee, or privacy guarantee. The
tool's execution gas estimate and `signedMaxGasCostWei` do not include all L1 data
fees or other chain-specific charges. Verify those and the signed fee limits
against the supplied USDC cost allowance before authorizing submission.

The skill requires explicit authorization for live submission. This package
never signs or broadcasts. After a separately authorized send, use the returned
transaction/bundle hash to check the receipt and then re-read order state. A
prepared request or accepted RPC response is not a completed fill.

## Validate

```sh
bun run --cwd "$ASYNCSWAP_FILLER_ROOT/packages/filler-tools" test
bun run --cwd "$ASYNCSWAP_FILLER_ROOT/packages/filler-tools" typecheck
```

Tests use controlled API/RPC fixtures to verify boundaries and transaction
encoding; they do not establish compatibility with a deployed contract. For
local integration, use `$ASYNCSWAP_FILLER_ROOT/dev/start-anvil-dev.sh` and test-only funds. That workflow
may seed mock/mock pools or legacy deployments; those are intentionally rejected
by these tools. Configure a current salt-based deployment and an approved
asset/USDC test pool for an end-to-end fill.
