'use strict';

const dotEnv = require('dotenv');
const dotEnvExpand = require('dotenv-expand');
const path = require('path');
const fs = require('fs');
const HDWalletProvider = require('truffle-hdwallet-provider');

if (!process.env.NODE_ENV) {
    console.warn('NODE_ENV not set! Assuming "development".');
}

const NODE_ENV = process.env.NODE_ENV || 'development';
const appDirectory = fs.realpathSync(process.cwd());
const dotEnvPath = path.resolve(appDirectory, '.env');

// Load .env files defined here: https://github.com/bkeepers/dotenv#what-other-env-files-can-i-use
// into process.env
[
    `${dotEnvPath}.${NODE_ENV}.local`,  // local override - .env.development.local, .env.production.local etc.
    `${dotEnvPath}.${NODE_ENV}`,        // environment specific - .env.development, .env.production
    NODE_ENV !== 'test' && `${dotEnvPath}.local`,   // .env.local is not included for tests
    dotEnvPath
]
    .filter(Boolean) // remove missing paths
    .forEach(dotEnvFile => {
        if (fs.existsSync(dotEnvFile)) {
            // apply env file
            dotEnvExpand(dotEnv.config({ path: dotEnvFile}));
        }
    });


module.exports = {
    solc: {
        optimizer: {
            enabled: true,
            runs: 200
        }
    },
    networks: {
        "mainnet": {
            network_id: 1,
            provider: () => {
                return new HDWalletProvider(process.env.MAINNET_MNEMONIC, process.env.MAINNET_URL);
            },
            gasPrice: 23000000000,
            // mainnet owner account - from must be all lowercase or a cryptic error will be thrown
            from: process.env.MAINNET_OWNER
        },

        "ropsten": {
            network_id: "3",
            provider: () => {
                return new HDWalletProvider(process.env.ROPSTEN_MNEMONIC, process.env.ROPSTEN_URL);
            },
            // ropsten test account - from must be all lowercase or a cryptic error will be thrown
            gasPrice: 23000000000,
            from: process.env.ROPSTEN_OWNER
        }
    },
    mocha: {
        useColors: false
    }
};
