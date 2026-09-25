import postgres from "postgres";
import { IncomingInviteItem, OutgoingInviteItem } from "../types/invite";
import { FriendWithLocation } from "../types/friend";

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

export async function updateUserProfile(
    env: Env,
    userId: number,
    name?: string,
    avatarUrl?: string
) {
    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });

    const [updatedUser] = await db`
        UPDATE public.users
        SET
            name = COALESCE(${name !== undefined ? name : null}, name),
            avatar_url = COALESCE(${avatarUrl !== undefined ? avatarUrl : null}, avatar_url),
            updated_at = NOW()
        WHERE id = ${userId}
        RETURNING id, name, avatar_url, email;
    `;

    return updatedUser;
}

export async function upsertUserLocation(
    env: Env,
    userId: number,
    latitude: number,
    longitude: number
) {
    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });

    await db`
        INSERT INTO public.locations (user_id, latitude, longitude, updated_at)
        VALUES (${userId}, ${latitude}, ${longitude}, NOW())
        ON CONFLICT (user_id) DO UPDATE SET
            latitude = EXCLUDED.latitude,
            longitude = EXCLUDED.longitude,
            updated_at = NOW();
    `;
}

export async function sendFriendInvite(
    env: Env,
    senderId: number,
    recipientId: number
): Promise<{ success: boolean; reason?: "not_found" | "already_friends" | "already_invited" }> {
    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });

    // Check if recipient exists
    const [recipient] = await db`
        SELECT id FROM public.users WHERE id = ${recipientId};
    `;
    if (!recipient) {
        return { success: false, reason: "not_found" };
    }

    // Check if already friends (matches your user_id and friend_id schema)
    const [friendship] = await db`
        SELECT 1 FROM public.friendships
        WHERE (user_id = ${senderId} AND friend_id = ${recipientId})
           OR (user_id = ${recipientId} AND friend_id = ${senderId});
    `;
    if (friendship) {
        return { success: false, reason: "already_friends" };
    }

    // Check for existing pending invite in either direction
    const [existingInvite] = await db`
        SELECT id FROM public.friend_requests
        WHERE (sender_id = ${senderId} AND receiver_id = ${recipientId})
           OR (sender_id = ${recipientId} AND receiver_id = ${senderId});
    `;
    if (existingInvite) {
        return { success: false, reason: "already_invited" };
    }

    // Insert new friend request
    await db`
        INSERT INTO public.friend_requests (sender_id, recipient_id, created_at)
        VALUES (${senderId}, ${recipientId}, NOW());
    `;

    return { success: true };
}

export async function getUserInvites(
    env: Env,
    userId: number
): Promise<{ incoming: IncomingInviteItem[]; outgoing: OutgoingInviteItem[] }> {
    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });

    const [incomingRows, outgoingRows] = await Promise.all([
        // Incoming: current user is receiver_id
        db`
            SELECT 
                fr.id,
                fr.created_at,
                u.id AS user_id,
                u.name AS user_name,
                u.avatar_url AS user_avatar
            FROM public.friend_requests fr
            JOIN public.users u ON fr.sender_id = u.id
            WHERE fr.receiver_id = ${userId}
            ORDER BY fr.created_at DESC;
        `,
        // Outgoing: current user is sender_id
        db`
            SELECT 
                fr.id,
                fr.created_at,
                u.id AS user_id,
                u.name AS user_name,
                u.avatar_url AS user_avatar
            FROM public.friend_requests fr
            JOIN public.users u ON fr.receiver_id = u.id
            WHERE fr.sender_id = ${userId}
            ORDER BY fr.created_at DESC;
        `
    ]);

    const incoming = incomingRows.map((row) => ({
        id: Number(row.id),
        sender: {
            id: Number(row.user_id),
            name: row.user_name,
            avatar: row.user_avatar,
        },
        created_at: new Date(row.created_at).toISOString(),
    }));

    const outgoing = outgoingRows.map((row) => ({
        id: Number(row.id),
        recipient: {
            id: Number(row.user_id),
            name: row.user_name,
            avatar: row.user_avatar,
        },
        created_at: new Date(row.created_at).toISOString(),
    }));

    return { incoming, outgoing };
}

export async function declineFriendInvite(
    env: Env,
    receiverId: number,
    senderId: number
): Promise<boolean> {
    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });

    const deletedRows = await db`
        DELETE FROM public.friend_requests
        WHERE sender_id = ${senderId} AND receiver_id = ${receiverId}
        RETURNING id;
    `;

    return deletedRows.length > 0;
}

export async function acceptFriendInvite(
    env: Env,
    receiverId: number,
    senderId: number
): Promise<{ success: boolean; reason?: "not_found" | "already_friends" }> {
    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });

    return await db.begin(async (sql) => {
        // Delete the pending invite and confirm it exists
        const [invite] = await sql`
            DELETE FROM public.friend_requests
            WHERE sender_id = ${senderId} AND receiver_id = ${receiverId}
            RETURNING id;
        `;

        if (!invite) {
            return { success: false, reason: "not_found" };
        }

        // Insert into friendships table
        await sql`
            INSERT INTO public.friendships (user_id, friend_id, created_at)
            VALUES (${senderId}, ${receiverId}, NOW())
            ON CONFLICT DO NOTHING;
        `;

        return { success: true };
    });
}

export async function deleteFriendship(
    env: Env,
    userId: number,
    friendId: number
): Promise<boolean> {
    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });

    const deletedRows = await db`
        DELETE FROM public.friendships
        WHERE (user_id = ${userId} AND friend_id = ${friendId})
           OR (user_id = ${friendId} AND friend_id = ${userId})
        RETURNING id;
    `;

    return deletedRows.length > 0;
}

export async function getFriendsWithLocations(
    env: Env,
    userId: number
): Promise<FriendWithLocation[]> {
    const db = postgres(env.HYPERDRIVE.connectionString, {
        max: 5,
        fetch_types: false,
        prepare: true,
    });


    const rows = await db`
        SELECT 
            u.id,
            u.name,
            u.avatar_url AS avatar,
            l.latitude,
            l.longitude,
            l.updated_at AS location_timestamp
        FROM public.friendships f
        JOIN public.users u 
          ON u.id = CASE 
                      WHEN f.user_id = ${userId} THEN f.friend_id 
                      ELSE f.user_id 
                    END
        LEFT JOIN public.locations l ON l.user_id = u.id
        WHERE f.user_id = ${userId} OR f.friend_id = ${userId}
        ORDER BY u.name ASC;
    `;

    return rows.map((row) => ({
        id: Number(row.id),
        name: row.name,
        avatar: row.avatar,
        location: row.latitude !== null && row.longitude !== null
            ? {
                latitude: String(row.latitude),
                longitude: String(row.longitude),
                timestamp: new Date(row.location_timestamp).toISOString(),
            }
            : null,
    }));
}