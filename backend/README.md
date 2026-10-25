# VOID AI gateway (no provider key in the Android app)

This Cloudflare Worker keeps the Gemini provider key on the server. The Android app sends requests to the Worker and authenticates with a separate private **gateway access token**. It is not a replacement for the provider credential: the owner still configures `GEMINI_API_KEY` as a Worker secret.

## Deploy

1. Create a Cloudflare account and install Node.js on a computer or Termux environment that supports npm.
2. Install Wrangler and sign in:

   ```sh
   npm install --global wrangler
   wrangler login
   ```

3. From this directory, set the two secrets. Use a new random gateway token; do not reuse passwords:

   ```sh
   cd backend
   wrangler secret put GEMINI_API_KEY
   wrangler secret put VOID_CLIENT_TOKEN
   wrangler deploy
   ```

   `GEMINI_API_KEY` is created in Google AI Studio. `VOID_CLIENT_TOKEN` is an app-to-gateway access secret. Neither belongs in GitHub source code. Do not commit either value.

4. Copy the deployed Worker URL (for example, `https://void-ai-gateway.<your-account>.workers.dev`). Open VOID AI → **ربط AI** and enter that HTTPS URL plus the exact `VOID_CLIENT_TOKEN` value.
5. Tap **اختبار AI**. The Worker health URL is `<worker-url>/health`; it reports whether the required server secrets exist but never returns them.

## Security notes

- The Worker allows only the app's required Gemini text-generation and Interactions API endpoints; it is not an unrestricted URL proxy.
- A small per-isolate IP rate limit is included as a basic guardrail, not a replacement for account-level quotas or production rate limiting.
- The app must not be distributed publicly with a shared gateway token. For multi-user distribution, add real user sign-in and per-user quotas before sharing it.
- Image/video generation can take substantially longer than chat and depends on upstream model availability, provider quotas, and request duration. No hosted proxy can guarantee zero latency.
- If you need **no key or credential anywhere**, a hosted online model is not a realistic guarantee. A local on-device model can avoid a hosted API key, but has different capability, memory, battery, and speed trade-offs.
