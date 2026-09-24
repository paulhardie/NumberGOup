// Cloudflare Pages refuses any single file over 25 MiB, and Godot's engine
// (index.wasm) is about 40 MB. The preview workflow uploads it gzipped as
// index.wasm.gz instead, and this worker serves it back under its real name
// with the encoding header, so the browser unpacks it as it downloads.
// Every other request goes straight to the uploaded files.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname !== "/index.wasm") {
      return env.ASSETS.fetch(request);
    }
    const packed = await env.ASSETS.fetch(new URL("/index.wasm.gz", url));
    if (!packed.ok) {
      return packed;
    }
    const headers = new Headers(packed.headers);
    headers.set("Content-Type", "application/wasm");
    headers.set("Content-Encoding", "gzip");
    headers.delete("Content-Length");
    // If the asset store already sent the file encoded, the runtime has
    // unpacked the body, so let it re-encode; otherwise pass the gzip bytes on.
    const encodeBody = packed.headers.has("Content-Encoding") ? "automatic" : "manual";
    return new Response(packed.body, { status: 200, headers, encodeBody });
  },
};
