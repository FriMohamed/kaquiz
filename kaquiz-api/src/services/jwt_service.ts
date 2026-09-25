export interface JwtPayload {
    sub: string;
    iat: number;
    exp: number;
}

function base64UrlEncode(data: object): string {
    const json = JSON.stringify(data);
    return btoa(json)
        .replace(/=/g, "")
        .replace(/\+/g, "-")
        .replace(/\//g, "_");
}

function base64UrlDecode(str: string): Uint8Array {
    let base64 = str.replace(/-/g, "+").replace(/_/g, "/");
    while (base64.length % 4) {
        base64 += "=";
    }

    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
    }
    return bytes;
}

/**
 * Generate a signed JWT access token for a user
 */
export async function generateAccessToken(
    userId: number,
    secret: string
): Promise<string> {
    const header = { alg: "HS256", typ: "JWT" };
    const now = Math.floor(Date.now() / 1000);
    const payload: JwtPayload = {
        sub: userId.toString(),
        iat: now,
        exp: now + 60 * 60 * 24 * 7, // 7 days expiration
    };

    const encodedHeader = base64UrlEncode(header);
    const encodedPayload = base64UrlEncode(payload);
    const tokenData = `${encodedHeader}.${encodedPayload}`;

    const key = await crypto.subtle.importKey(
        "raw",
        new TextEncoder().encode(secret),
        { name: "HMAC", hash: "SHA-256" },
        false,
        ["sign"]
    );

    const signature = await crypto.subtle.sign(
        "HMAC",
        key,
        new TextEncoder().encode(tokenData)
    );

    const encodedSignature = btoa(
        String.fromCharCode(...new Uint8Array(signature))
    )
        .replace(/=/g, "")
        .replace(/\+/g, "-")
        .replace(/\//g, "_");

    return `${tokenData}.${encodedSignature}`;
}

/**
 * Verify a JWT access token and return the payload if valid
 */
export async function verifyAccessToken(
    token: string,
    secret: string
): Promise<JwtPayload | null> {
    const parts = token.split(".");
    if (parts.length !== 3) return null;

    const [encodedHeader, encodedPayload, encodedSignature] = parts;
    const tokenData = `${encodedHeader}.${encodedPayload}`;

    try {
        const key = await crypto.subtle.importKey(
            "raw",
            new TextEncoder().encode(secret),
            { name: "HMAC", hash: "SHA-256" },
            false,
            ["verify"]
        );

        const signature = base64UrlDecode(encodedSignature);
        const isValid = await crypto.subtle.verify(
            "HMAC",
            key,
            signature.buffer as ArrayBuffer,
            new TextEncoder().encode(tokenData)
        );

        if (!isValid) return null;

        const payloadText = new TextDecoder().decode(
            base64UrlDecode(encodedPayload)
        );
        const payload = JSON.parse(payloadText) as JwtPayload;

        // Check token expiration
        const now = Math.floor(Date.now() / 1000);
        if (payload.exp && payload.exp < now) {
            return null;
        }

        return payload;
    } catch {
        return null; // Invalid signature format, JSON parse error, etc.
    }
}