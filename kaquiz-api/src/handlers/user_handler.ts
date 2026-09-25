import type { UpdateUserInput } from "../types/user";
import { updateUserProfile } from "../db/supabase";

export async function updateUserHandler(
    env: Env,
    request: Request,
    userId: number
): Promise<Response> {
    let body: UpdateUserInput = {};
    const text = await request.text();

    if (text.trim().length > 0) {
        try {
            body = JSON.parse(text);
        } catch {
            return Response.json(
                { error: "Invalid JSON body" },
                { status: 400 }
            );
        }
    }

    const { name, avatar } = body;

    if (name !== undefined && (typeof name !== "string" || !name.trim())) {
        return Response.json({ error: "Invalid name" }, { status: 400 });
    }

    if (avatar !== undefined && typeof avatar !== "string") {
        return Response.json({ error: "Invalid avatar URL" }, { status: 400 });
    }

    try {
        const user = await updateUserProfile(
            env,
            userId,
            name?.trim(),
            avatar?.trim()
        );

        if (!user) {
            return Response.json({ error: "User not found" }, { status: 404 });
        }

        return Response.json(
            {
                id: Number(user.id),
                name: user.name,
                avatar: user.avatar_url,
                email: user.email,
            },
            { status: 200 }
        );
    } catch (error) {
        return Response.json({ error: "Internal server error" }, { status: 500 });
    }
}