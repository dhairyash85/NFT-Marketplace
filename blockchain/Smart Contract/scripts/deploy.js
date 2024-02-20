async function main() {
  const NFT = await ethers.getContractFactory("NFT");
  const nft = await NFT.deploy();
  console.log("NFT address:", nft.address);
  const Marketplace = await ethers.getContractFactory("Marketplace");
  const mp = await Marketplace.deploy(2);
  console.log("Marketplace address:", mp.address);
}

main()
 .then(() => process.exit(0))
 .catch(error => {
   console.error(error);
   process.exit(1);
 });