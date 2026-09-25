import { authHandler } from "./handlers/auth_handler";
import { sendInviteHandler, getInvitesHandler, declineInviteHandler, acceptInviteHandler } from "./handlers/invite_handler";
import { submitLocationHandler } from "./handlers/location_handler";
import { updateUserHandler } from "./handlers/user_handler";
import { authenticateRequest } from "./middleware/auth";
import { deleteFriendHandler, getFriendsHandler } from "./handlers/friend_handler";

export default {
    async fetch(request, env, ctx): Promise<Response> {
        const url = new URL(request.url);

        // Route: /api/auth
        if (request.method === "POST" && url.pathname === "/api/auth") {
            return authHandler(env, request);
        }

        const authHeader = request.headers.get("authorization");
        const userId = await authenticateRequest(authHeader, env.JWT_SECRET);

        if (!userId) {
            return Response.json({ error: "Unauthorized" }, { status: 401 });
        }

        // Route: /api/users
        if (request.method === "PUT" && url.pathname === "/api/users") {
            return updateUserHandler(env, request, userId);
        }

        // Route: /api/locations
        if (request.method === "POST" && url.pathname === "/api/locations") {
            return submitLocationHandler(env, request, userId);
        }

        // Route: /api/invites/{user_id}/   
        const inviteMatch = url.pathname.match(/^\/api\/invites\/(\d+)$/);
        if (inviteMatch) {
            const targetUserIdParam = inviteMatch[1];
            if (request.method === "POST") {
                return sendInviteHandler(env, userId, targetUserIdParam);
            }

            if (request.method === "GET") {
                return getInvitesHandler(env, userId);
            }
        }

        // Route: /api/invites/{user_id}/decline
        const declineMatch = url.pathname.match(/^\/api\/invites\/(\d+)\/decline$/);
        if (request.method === "POST" && declineMatch) {
            return declineInviteHandler(env, userId, declineMatch[1]);
        }

        // Route: /api/invites/{user_id}/accept
        const acceptMatch = url.pathname.match(/^\/api\/invites\/(\d+)\/accept$/);
        if (request.method === "POST" && acceptMatch) {
            return acceptInviteHandler(env, userId, acceptMatch[1]);
        }

        // Route: GET /api/friends
        if (request.method === "GET" && url.pathname === "/api/friends") {
            return getFriendsHandler(env, userId);
        }

        // Route: DELETE /api/friends/{id}
        const friendDeleteMatch = url.pathname.match(/^\/api\/friends\/(\d+)$/);
        if (request.method === "DELETE" && friendDeleteMatch) {
            return deleteFriendHandler(env, userId, friendDeleteMatch[1]);
        }

        return new Response("Not Found", { status: 404 });
    },
} satisfies ExportedHandler<Env>;