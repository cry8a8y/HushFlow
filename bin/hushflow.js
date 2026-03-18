#!/usr/bin/env node
const { execFileSync } = require("child_process");
const { join } = require("path");

const cli = join(__dirname, "..", "cli.sh");
const args = process.argv.slice(2);

try {
  execFileSync("bash", [cli, ...args], { stdio: "inherit" });
} catch (e) {
  process.exit(e.status || 1);
}
