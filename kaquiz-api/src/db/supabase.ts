import postgres from "postgres";

export async function upsertGoogleUser(
    env: Env,
    googleId: string,
    email: string,
    name: string,
    avatarUrl: string | null,
) {
    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });

    const [user] = await db`
        INSERT INTO users (
            google_id,
            email,
            name,
            avatar_url
        )
        VALUES (
            ${googleId},
            ${email},
            ${name},
            ${avatarUrl}
        )
        ON CONFLICT (google_id) DO UPDATE SET
            name = EXCLUDED.name,
            avatar_url = COALESCE(EXCLUDED.avatar_url, users.avatar_url),
            updated_at = NOW()
        RETURNING id, name, email, avatar_url, created_at, updated_at
    `;

    return user;
}