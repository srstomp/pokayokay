#!/usr/bin/env node

import { main } from '../src/index.js';
import { doctor } from '../src/doctor.js';

const command = process.argv[2];

if (command === 'doctor') {
  doctor().catch((err) => {
    console.error(`\n  Doctor failed: ${err.message}\n`);
    process.exit(1);
  });
} else if (command === 'help' || command === '--help' || command === '-h') {
  console.log(`
  pokayokay setup wizard

  Usage:
    npx pokayokay          Run interactive setup wizard
    npx pokayokay doctor   Validate installation
    npx pokayokay help     Show this help message
`);
} else {
  main().catch((err) => {
    console.error(`\n  Setup failed: ${err.message}\n`);
    process.exit(1);
  });
}
