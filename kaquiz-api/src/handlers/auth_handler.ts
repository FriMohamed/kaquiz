import type { AuthInput } from "../types/auth";
import { authenticateWithGoogle } from "../services/auth_service";

export async function authHandler(
    env: Env,
    request: Request,
): Promise<Response> {
    let body: AuthInput;

    try {
        body = await request.json();
    } catch {
        return Response.json(
            { error: "Invalid JSON" },
            { status: 400 },
        );
    }

    if (typeof body.id_token !== "string" || !body.id_token.trim()) {
        return Response.json(
            { error: "id_token is required" },
            { status: 400 },
        );
    }

    return authenticateWithGoogle(env, body.id_token.trim());
}