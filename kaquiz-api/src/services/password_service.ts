import {
    argon2id,
    argon2Verify,
    setWASMModules,
} from "argon2-wasm-edge";

// @ts-expect-error Cloudflare Worker WASM import
import argon2WASM from "argon2-wasm-edge/wasm/argon2.wasm";

// @ts-expect-error Cloudflare Worker WASM import
import blake2bWASM from "argon2-wasm-edge/wasm/blake2b.wasm";

setWASMModules({
    argon2WASM,
    blake2bWASM,
});

const ARGON2_OPTIONS = {
    parallelism: 1,
    iterations: 256,
    memorySize: 512,
    hashLength: 32,
    outputType: "encoded" as const,
};

export async function hashPassword(password: string): Promise<string> {
    const salt = crypto.getRandomValues(new Uint8Array(16));

    return argon2id({
        ...ARGON2_OPTIONS,
        password,
        salt,
    });
}

export async function verifyPassword(
    password: string,
    hash: string,
): Promise<boolean> {
    return argon2Verify({
        password,
        hash,
    });
}