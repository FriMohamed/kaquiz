import { deleteFriendship, getFriendsWithLocations } from "../db/supabase";

export async function deleteFriendHandler(
    env: Env,
    authUserId: number,
    targetFriendIdParam: string
): Promise<Response> {
    const friendId = parseInt(targetFriendIdParam, 10);

    if (isNaN(friendId) || friendId <= 0) {
        return Response.json({ error: "Invalid friend ID" }, { status: 400 });
    }

    if (authUserId === friendId) {
        return Response.json(
            { error: "Cannot remove yourself as a friend" },
            { status: 400 }
        );
    }

    try {
        const deleted = await deleteFriendship(env, authUserId, friendId);

        if (!deleted) {
            return Response.json({ error: "Friend not found" }, { status: 404 });
        }

        return Response.json(
            { message: "Friend deleted successfully" },
            { status: 200 }
        );
    } catch (error) {
        console.error("Failed to delete friend:", error);
        return Response.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function getFriendsHandler(
    env: Env,
    authUserId: number
): Promise<Response> {
    try {
        const friends = await getFriendsWithLocations(env, authUserId);
        return Response.json(friends, { status: 200 });
    } catch (error) {
        console.error("Failed to fetch friends:", error);
        return Response.json({ error: "Internal server error" }, { status: 500 });
    }
}