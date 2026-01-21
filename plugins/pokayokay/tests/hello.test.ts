import { strict as assert } from 'assert';
import { greet } from './hello';

// Test: greet function returns proper greeting
function testGreet() {
  const result = greet('World');
  assert.equal(result, 'Hello, World!', 'greet should return "Hello, World!"');
  console.log('PASS: greet("World") returns "Hello, World!"');
}

function testGreetWithName() {
  const result = greet('Alice');
  assert.equal(result, 'Hello, Alice!', 'greet should return "Hello, Alice!"');
  console.log('PASS: greet("Alice") returns "Hello, Alice!"');
}

function testGreetWithEmptyString() {
  const result = greet('');
  assert.equal(result, 'Hello, !', 'greet should handle empty string');
  console.log('PASS: greet("") returns "Hello, !"');
}

// Run tests
console.log('Running hello.ts tests...\n');

try {
  testGreet();
  testGreetWithName();
  testGreetWithEmptyString();
  console.log('\nAll tests passed!');
} catch (error) {
  console.error('\nTest failed:', error);
  process.exit(1);
}
