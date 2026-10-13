import { cpSync, existsSync, mkdirSync } from "node:fs";
import { resolve, join } from "node:path";
import { fileURLToPath } from "node:url";

const checkoutArg = process.argv[2];
if (!checkoutArg) {
  console.error("Usage: bun run scripts/sync-filler-skill.ts /path/to/application-checkout");
  process.exit(2);
}
const checkout = resolve(checkoutArg);
if (!existsSync(join(checkout, "packages/filler-tools/src/cli.ts"))) {
  console.error("Destination must be a checkout containing packages/filler-tools/src/cli.ts");
  process.exit(2);
}
const source = fileURLToPath(new URL("../plugins/asyncswap-filler/skills/asyncswap-filler", import.meta.url));
const destination = join(checkout, ".agents/skills/asyncswap-filler");
mkdirSync(destination, { recursive: true });
cpSync(source, destination, { recursive: true });
console.log(`Synced canonical filler skill to ${destination}`);
