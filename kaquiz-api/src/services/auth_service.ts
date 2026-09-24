import { createUser } from "../db/supabase";
import type { RegisterInput } from "../types/auth";
import { hashPassword } from "./password_service";


export async function register(
    env: Env,
    input: RegisterInput,
): Promise<Response> {
    const name = input.name.trim();
    const email = input.email.trim().toLowerCase();
    const password = input.password;

    if (name.length < 2 || name.length > 30) {
        return Response.json(
            { error: "Name must be between 2 and 30 characters" },
            { status: 400 },
        );
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(email) || email.length > 254) {
        return Response.json(
            { error: "Invalid email" },
            { status: 400 },
        );
    }

    if (password.length < 8 || password.length > 128) {
        return Response.json(
            { error: "Password must be between 8 and 128 characters" },
            { status: 400 },
        );
    }

    const passwordHash = await hashPassword(password);

    try {
        const user = await createUser(
            env,
            name,
            email,
            passwordHash,
        );

        return Response.json(
            { user },
            { status: 201 },
        );
    } catch (error) {
        // PostgreSQL unique violation
        if (
            typeof error === "object" &&
            error !== null &&
            "code" in error &&
            error.code === "23505"
        ) {
            return Response.json(
                { error: "Email already exists" },
                { status: 409 },
            );
        }

        console.error("Failed to create user:", error);

        return Response.json(
            { error: "Internal server error" },
            { status: 500 },
        );
    }
}