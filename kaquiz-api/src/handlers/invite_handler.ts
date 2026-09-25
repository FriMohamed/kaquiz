import { sendFriendInvite, getUserInvites, declineFriendInvite, acceptFriendInvite } from "../db/supabase";

export async function sendInviteHandler(
    env: Env,
    senderId: number,
    recipientIdParam: string
): Promise<Response> {
    const recipientId = parseInt(recipientIdParam, 10);

    // Validate path parameter
    if (isNaN(recipientId) || recipientId <= 0) {
        return Response.json({ error: "Invalid user ID" }, { status: 400 });
    }

    // Prevent self-invitation
    if (senderId === recipientId) {
        return Response.json(
            { error: "You cannot send a friend invite to yourself" },
            { status: 400 }
        );
    }

    try {
        const result = await sendFriendInvite(env, senderId, recipientId);

        if (!result.success) {
            if (result.reason === "not_found") {
                return Response.json({ error: "User not found" }, { status: 404 });
            }
            if (result.reason === "already_friends") {
                return Response.json(
                    { error: "You are already friends with this user" },
                    { status: 400 }
                );
            }
            if (result.reason === "already_invited") {
                return Response.json(
                    { error: "A friend request already exists between these users" },
                    { status: 400 }
                );
            }
        }

        return Response.json(
            { message: "Invitation sent successfully" },
            { status: 200 }
        );
    } catch (error) {
        return Response.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function getInvitesHandler(
    env: Env,
    authUserId: number,
): Promise<Response> {
    try {
        const invites = await getUserInvites(env, authUserId);
        return Response.json(invites, { status: 200 });
    } catch (error) {
        console.error("Failed to fetch invites:", error);
        return Response.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function declineInviteHandler(
    env: Env,
    receiverId: number,
    senderIdParam: string
): Promise<Response> {
    const senderId = parseInt(senderIdParam, 10);

    if (isNaN(senderId) || senderId <= 0) {
        return Response.json({ error: "Invalid user ID" }, { status: 400 });
    }

    try {
        const found = await declineFriendInvite(env, receiverId, senderId);

        if (!found) {
            return Response.json({ error: "Invitation not found" }, { status: 404 });
        }

        return Response.json(
            { message: "Invitation declined successfully" },
            { status: 200 }
        );
    } catch (error) {
        console.error("Failed to decline invite:", error);
        return Response.json({ error: "Internal server error" }, { status: 500 });
    }
}

export async function acceptInviteHandler(
    env: Env,
    receiverId: number,
    senderIdParam: string
): Promise<Response> {
    const senderId = parseInt(senderIdParam, 10);

    if (isNaN(senderId) || senderId <= 0) {
        return Response.json({ error: "Invalid user ID" }, { status: 400 });
    }

    try {
        const result = await acceptFriendInvite(env, receiverId, senderId);

        if (!result.success) {
            return Response.json({ error: "Invitation not found" }, { status: 404 });
        }

        return Response.json(
            { message: "Invitation accepted successfully" },
            { status: 200 }
        );
    } catch (error) {
        console.error("Failed to accept invite:", error);
        return Response.json({ error: "Internal server error" }, { status: 500 });
    }
}