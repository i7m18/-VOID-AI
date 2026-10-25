const MAX_PER_MINUTE = 40;
const recentCalls = new Map();

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Authorization, Content-Type",
    "Access-Control-Expose-Headers": "Retry-After",
    "Cache-Control": "no-store",
    "Vary": "Origin"
  };
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders(), "Content-Type": "application/json; charset=utf-8" }
  });
}

function safeEqual(a, b) {
  const encoder = new TextEncoder();
  const left = encoder.encode(a);
  const right = encoder.encode(b);
  if (left.length !== right.length) return false;
  let diff = 0;
  for (let i = 0; i < left.length; i++) diff |= left[i] ^ right[i];
  return diff === 0;
}

function isRateLimited(ip) {
  const now = Date.now();
  const cutoff = now - 60_000;
  const kept = (recentCalls.get(ip) || []).filter((time) => time > cutoff);
  if (kept.length >= MAX_PER_MINUTE) {
    recentCalls.set(ip, kept);
    return true;
  }
  kept.push(now);
  recentCalls.set(ip, kept);
  if (recentCalls.size > 1500) {
    for (const [key, times] of recentCalls) {
      if (!times.some((time) => time > cutoff)) recentCalls.delete(key);
      if (recentCalls.size <= 1200) break;
    }
  }
  return false;
}

function isAllowed(method, pathname) {
  if (method === "POST" && pathname === "/v1beta/models/gemini-3.8-flash:generateContent") return true;
  if (method === "POST" && pathname === "/v1beta/interactions") return true;
  if (method === "GET" && /^\/v1beta\/interactions\/[A-Za-z0-9_-]+$/.test(pathname)) return true;
  return false;
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders() });
    }

    const url = new URL(request.url);
    if (request.method === "GET" && url.pathname === "/health") {
      return json({ service: "VOID AI gateway", ready: Boolean(env.GEMINI_API_KEY && env.VOID_CLIENT_TOKEN) });
    }

    if (!isAllowed(request.method, url.pathname)) {
      return json({ error: { message: "Endpoint or method is not allowed." } }, 404);
    }

    if (!env.GEMINI_API_KEY || !env.VOID_CLIENT_TOKEN) {
      return json({ error: { message: "Server is not configured: add GEMINI_API_KEY and VOID_CLIENT_TOKEN secrets." } }, 503);
    }

    const supplied = (request.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
    if (!supplied || !safeEqual(supplied, env.VOID_CLIENT_TOKEN)) {
      return json({ error: { message: "Invalid VOID AI gateway access token." } }, 401);
    }

    const ip = request.headers.get("CF-Connecting-IP") || "unknown";
    if (isRateLimited(ip)) {
      return json({ error: { message: "Too many requests. Please retry in a minute." } }, 429);
    }

    const upstreamUrl = new URL("https://generativelanguage.googleapis.com" + url.pathname + url.search);
    const headers = new Headers();
    headers.set("x-goog-api-key", env.GEMINI_API_KEY);
    headers.set("Accept", request.headers.get("Accept") || "application/json");
    if (request.method === "POST") {
      headers.set("Content-Type", request.headers.get("Content-Type") || "application/json");
    }

    try {
      const upstream = await fetch(upstreamUrl.toString(), {
        method: request.method,
        headers,
        body: request.method === "POST" ? request.body : undefined,
        redirect: "manual"
      });
      const responseHeaders = new Headers(corsHeaders());
      responseHeaders.set("Content-Type", upstream.headers.get("Content-Type") || "application/json");
      const retryAfter = upstream.headers.get("Retry-After");
      if (retryAfter) responseHeaders.set("Retry-After", retryAfter);
      return new Response(upstream.body, { status: upstream.status, headers: responseHeaders });
    } catch (_error) {
      return json({ error: { message: "Unable to reach the AI provider. Check the upstream service and try again." } }, 502);
    }
  }
};
