import type { SubmitLocationInput } from "../types/location";
import { upsertUserLocation } from "../db/supabase";

export async function submitLocationHandler(
    env: Env,
    request: Request,
    userId: number
): Promise<Response> {
    const text = await request.text();
    if (!text.trim()) {
        return Response.json(
            { error: "Latitude and longitude are required" },
            { status: 400 }
        );
    }

    let body: SubmitLocationInput;
    try {
        body = JSON.parse(text);
    } catch {
        return Response.json(
            { error: "Invalid JSON body" },
            { status: 400 }
        );
    }

    const { latitude, longitude } = body;

    // Validate type
    if (typeof latitude !== "number" || typeof longitude !== "number") {
        return Response.json(
            { error: "Latitude and longitude must be valid numbers" },
            { status: 400 }
        );
    }

    // Validate coordinate ranges
    if (latitude < -90 || latitude > 90) {
        return Response.json(
            { error: "Latitude must be between -90 and 90" },
            { status: 400 }
        );
    }

    if (longitude < -180 || longitude > 180) {
        return Response.json(
            { error: "Longitude must be between -180 and 180" },
            { status: 400 }
        );
    }

    try {
        await upsertUserLocation(env, userId, latitude, longitude);
        return Response.json(
            { message: "Location updated successfully" },
            { status: 200 }
        );
    } catch (error) {
        return Response.json(
            { error: "Internal server error" },
            { status: 500 }
        );
    }
}