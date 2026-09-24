import type { RegisterInput } from "../types/auth";
import { register } from "../services/auth_service";

export async function registerHandler(
    env: Env,
    request: Request,
): Promise<Response> {
    let body: RegisterInput;

    try {
        body = await request.json();
    } catch {
        return Response.json(
            { error: "Invalid JSON" },
            { status: 400 },
        );
    }

    if (
        typeof body.name !== "string" ||
        typeof body.email !== "string" ||
        typeof body.password !== "string" ||
        !body.name.trim() ||
        !body.email.trim() ||
        !body.password
    ) {
        return Response.json(
            { error: "Name, email and password are required" },
            { status: 400 },
        );
    }

    return register(env, body);
}