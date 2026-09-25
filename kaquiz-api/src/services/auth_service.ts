import { upsertGoogleUser } from "../db/supabase";
import { generateAccessToken } from "./jwt_service";

export async function authenticateWithGoogle(
    env: Env,
    idToken: string,
): Promise<Response> {
    try {
        // Verify Google ID Token against Google's public tokeninfo endpoint
        const googleRes = await fetch(
            `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`
        );

        if (!googleRes.ok) {
            return Response.json(
                { error: "Invalid ID token" },
                { status: 400 },
            );
        }

        const payload = await googleRes.json() as {
            sub?: string;
            email?: string;
            name?: string;
            picture?: string;
        };

        if (!payload.sub || !payload.email) {
            return Response.json(
                { error: "Token payload missing required fields" },
                { status: 400 },
            );
        }

        const googleId = payload.sub;
        const email = payload.email.toLowerCase();
        const name = payload.name || email.split("@")[0];
        const avatarUrl = payload.picture || null;

        // Upsert user record in Postgres via Hyperdrive
        const user = await upsertGoogleUser(
            env,
            googleId,
            email,
            name,
            avatarUrl,
        );

        // Generate internal app Access Token (JWT)
        const accessToken = await generateAccessToken(user.id, env.JWT_SECRET);

        // Return response strictly matching Swagger spec schema
        return Response.json(
            { access_token: accessToken },
            { status: 200 },
        );
    } catch (error) {
        console.error("Authentication failed:", error);

        return Response.json(
            { error: "Internal server error" },
            { status: 500 },
        );
    }
}