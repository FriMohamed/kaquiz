import { registerHandler } from "./handlers/auth_handler";

export default {
	async fetch(request, env, ctx): Promise<Response> {
		const url = new URL(request.url);

		if (
			request.method === "POST" &&
			url.pathname === "/api/auth/register"
		) {
			return registerHandler(env, request);
		}

		return new Response("Not Found", { status: 404 });
	},
} satisfies ExportedHandler<Env>;

