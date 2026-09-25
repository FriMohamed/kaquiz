import { verifyAccessToken } from "../services/jwt_service";

/**
 * Extracts and verifies JWT from the Authorization header.
 * Returns the numeric userId if valid, or null if unauthorized.
 */
export async function authenticateRequest(
    authHeader: string | null,
    secret: string
): Promise<number | null> {
    if (!authHeader) return null;

    // Supports both "Bearer <token>" and raw token string
    const token = authHeader.startsWith("Bearer ")
        ? authHeader.slice(7).trim()
        : authHeader.trim();

    if (!token) return null;

    const payload = await verifyAccessToken(token, secret);
    if (!payload || !payload.sub) return null;

    const userId = parseInt(payload.sub, 10);
    return isNaN(userId) ? null : userId;
}