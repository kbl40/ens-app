const main = async () => {
    const domainContractFactory = await hre.ethers.getContractFactory('Domains');
    const domainContract = await domainContractFactory.deploy("bear");
    await domainContract.deployed();

    console.log("Contract deployed to:", domainContract.address);

    let txn = await domainContract.register("circus", {value: hre.ethers.utils.parseEther('0.1')});
    await txn.wait();
    console.log("Minted domain circus.bear");

    txn = await domainContract.setRecord("circus", "Do I need to wear a tutu?");
    await txn.wait();
    console.log("set record for circus.bear")

    const address = await domainContract.getAddress("circus");
    console.log("Owner of domain circus:", address);

    const balance = await hre.ethers.provider.getBalance(domainContract.address);
    console.log("Contract balance:", hre.ethers.utils.formatEther(balance));

    txn = await domainContract.setTwitter("circus", "@kylelackinger");
    await txn.wait();
    console.log("Twitter handle set");

    const twitter = await domainContract.getTwitter("circus");
    console.log("Twitter handle:", twitter);
}

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();