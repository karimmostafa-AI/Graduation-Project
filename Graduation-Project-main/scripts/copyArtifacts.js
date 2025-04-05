const fs = require('fs');
const path = require('path');

// Source and target paths
const sourceFile = path.join(__dirname, '../artifacts/contracts/GovernmentPropertyVerification.sol/GovernmentPropertyVerification.json');
const targetDir = path.join(__dirname, '../frontend/contracts');
const targetFile = path.join(targetDir, 'GovernmentPropertyVerification.json');

// Ensure target directory exists
if (!fs.existsSync(targetDir)) {
  fs.mkdirSync(targetDir, { recursive: true });
}

try {
  // Check if source exists
  if (!fs.existsSync(sourceFile)) {
    console.error('Source artifact file not found! Please compile contracts first.');
    process.exit(1);
  }

  // Just copy the entire artifact file
  fs.copyFileSync(sourceFile, targetFile);
  console.log('Contract artifacts copied successfully to:', targetDir);
} catch (error) {
  console.error('Error copying artifacts:', error);
  process.exit(1);
}
