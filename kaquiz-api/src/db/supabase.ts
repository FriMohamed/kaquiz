import postgres from "postgres";

export async function createUser(
    env: Env,
    name: string,
    email: string,
    passwordHash: string,
) {

    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });


    const [user] = await db`
        INSERT INTO users (
            name,
            email,
            password_hash
        )
        VALUES (
            ${name},
            ${email},
            ${passwordHash}
        )
        RETURNING id, name, email, avatar_url, created_at, updated_at
    `;

    return user;
}