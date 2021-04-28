const NightLifeCrypto = artifacts.require("NightLifeCrypto");
const NightLifeStaking = artifacts.require("NightLifeStaking");

module.exports = function(deployer) {
  deployer
    .deploy(NightLifeCrypto)
    .then(() => {
      return deployer.deploy(NightLifeStaking, NightLifeCrypto.address);
    });
};
