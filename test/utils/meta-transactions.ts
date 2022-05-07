import { BigNumberish, BytesLike, Signer } from "ethers";

export type UnorderedMetaTransaction = {
  signer: string;
  value: BigNumberish;
  minGasPrice: BigNumberish;
  maxGasPrice: BigNumberish;
  expiresAt: BigNumberish;
  salt: BigNumberish;
  callData: BytesLike;
};

export const EIP712_UMTX_TYPES = {
  UnorderedMetaTransaction: [
    { name: "signer", type: "address" },
    { name: "value", type: "uint256" },
    { name: "minGasPrice", type: "uint256" },
    { name: "maxGasPrice", type: "uint256" },
    { name: "expiresAt", type: "uint256" },
    { name: "salt", type: "uint256" },
    { name: "callData", type: "bytes" },
  ],
};

export const signUnorderedMetaTransaction = async (
  account: Signer,
  chainId: number,
  metaTransaction: UnorderedMetaTransaction,
  verifyingContract: string
) => {
  // @ts-ignore
  return await account._signTypedData(
    {
      name: "UnorderedMetaTransactions",
      version: "v0.1",
      chainId,
      verifyingContract,
    },
    EIP712_UMTX_TYPES,
    metaTransaction
  );
};
