#!/usr/bin/env python3
"""Maintainer-only: a scripted fake model on localhost. No AI, no credentials, no network.

It answers the Anthropic Messages API (/v1/messages) and the OpenAI Chat Completions API (/v1/chat/completions),
streaming or not, and saves every request body as <log dir>/<n>.json. The proofs grep those requests for what
each tool really sends to a model (skill listings, offered tools).

By default it answers every request with the text "ok". If <log dir>/probe.json exists, the first request of a
conversation that offers tools is answered with ONE tool call instead, and the next turn (after the tool result)
with "ok". probe.json:
  {"names": ["write", "Write"], "path": "/abs/file", "content": "x", "command": "touch /abs/file"}
The first name the request offers is called; if none is offered, the first name is called anyway, to see whether
the tool refuses a tool it did not offer. Arguments are filled from the tool's JSON schema (required keys, and any
key naming a path, content or command):
keys with "path" get `path`, "content" gets `content`, "command" gets `command`, anything else a short string.
Usage: fake-model.py <log dir> [--port 8766]
"""
import itertools
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOG = os.path.realpath(sys.argv[1]) if len(sys.argv) > 1 else sys.exit(__doc__)
COUNT = itertools.count(1)


def probe():
    try:
        with open(os.path.join(LOG, "probe.json")) as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def offered(req):
    """name -> JSON schema, for Anthropic and OpenAI shapes."""
    out = {}
    for t in req.get("tools") or []:
        if "function" in t:
            out[t["function"].get("name")] = t["function"].get("parameters") or {}
        elif "name" in t:
            out[t["name"]] = t.get("input_schema") or {}
    return out


def answered(req):
    """True once the conversation holds a tool result: then the probe is over."""
    for m in req.get("messages") or []:
        if m.get("role") == "tool":
            return True
        c = m.get("content")
        if isinstance(c, list) and any(isinstance(b, dict) and b.get("type") in ("tool_result", "function_call_output") for b in c):
            return True
    return False


def plan_call(req):
    p = probe()
    tools = offered(req)
    if not p or not tools or answered(req):
        return None
    name = next((n for n in p["names"] if n in tools), p["names"][0])
    schema = tools.get(name) or {}
    args = {}
    props = schema.get("properties") or {}
    keys = list(schema.get("required") or [])
    keys += [k for k in props if k not in keys and any(w in k.lower() for w in ("path", "content", "command"))]
    for key in keys:
        k = key.lower()
        if "path" in k:
            args[key] = p.get("path", "/tmp/probe")
        elif "content" in k:
            args[key] = p.get("content", "probe")
        elif "command" in k:
            args[key] = p.get("command", "true")
        elif props.get(key, {}).get("type") == "boolean":
            args[key] = False
        else:
            args[key] = "probe"
    if name not in tools:  # a tool the request did not offer: guess the usual argument names
        args = {"command": p.get("command", "true"), "file_path": p.get("path"), "path": p.get("path"),
                "filePath": p.get("path"), "content": p.get("content", "probe"), "description": "probe"}
    with open(os.path.join(LOG, "calls.log"), "a") as f:
        f.write(json.dumps({"name": name, "offered": name in tools, "args": args}) + "\n")
    return name, args


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, *a):
        pass

    def send(self, code, body, ctype="application/json"):
        data = body.encode() if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path.rstrip("/").endswith("/models"):
            return self.send(200, json.dumps({"object": "list", "data": [{"id": "fake-1", "object": "model"}]}))
        self.send(404, "{}")

    def do_HEAD(self):
        self.send(200, "")

    def do_POST(self):
        raw = self.rfile.read(int(self.headers.get("Content-Length") or 0))
        try:
            req = json.loads(raw or b"{}")
        except ValueError:
            req = {"raw": raw.decode(errors="replace")}
        with open(os.path.join(LOG, f"{next(COUNT)}.json"), "w") as f:
            json.dump({"path": self.path, "body": req}, f)
        stream = bool(req.get("stream"))
        if "/messages" in self.path and "count_tokens" in self.path:
            return self.send(200, json.dumps({"input_tokens": 1}))
        call = plan_call(req)
        if "/messages" in self.path:
            return self.anthropic(req, stream, call)
        return self.openai(req, stream, call)

    def anthropic(self, req, stream, call):
        if call:
            block = {"type": "tool_use", "id": "toolu_fake1", "name": call[0], "input": call[1]}
            stop = "tool_use"
        else:
            block = {"type": "text", "text": "ok"}
            stop = "end_turn"
        msg = {"id": "msg_fake", "type": "message", "role": "assistant", "model": req.get("model", "fake"),
               "content": [block], "stop_reason": stop, "stop_sequence": None,
               "usage": {"input_tokens": 1, "output_tokens": 1}}
        if not stream:
            return self.send(200, json.dumps(msg))
        start = dict(block, input={}) if call else dict(block, text="")
        delta = ({"type": "input_json_delta", "partial_json": json.dumps(call[1])} if call
                 else {"type": "text_delta", "text": "ok"})
        ev = [("message_start", {"type": "message_start", "message": dict(msg, content=[], stop_reason=None)}),
              ("content_block_start", {"type": "content_block_start", "index": 0, "content_block": start}),
              ("content_block_delta", {"type": "content_block_delta", "index": 0, "delta": delta}),
              ("content_block_stop", {"type": "content_block_stop", "index": 0}),
              ("message_delta", {"type": "message_delta", "delta": {"stop_reason": stop, "stop_sequence": None},
                                 "usage": {"output_tokens": 1}}),
              ("message_stop", {"type": "message_stop"})]
        return self.send(200, "".join(f"event: {e}\ndata: {json.dumps(d)}\n\n" for e, d in ev), "text/event-stream")

    def openai(self, req, stream, call):
        base = {"id": "chatcmpl-fake", "created": 0, "model": req.get("model", "fake")}
        usage = {"prompt_tokens": 1, "completion_tokens": 1, "total_tokens": 2}
        tc = [{"index": 0, "id": "call_fake1", "type": "function",
               "function": {"name": call[0], "arguments": json.dumps(call[1])}}] if call else None
        finish = "tool_calls" if call else "stop"
        if not stream:
            message = {"role": "assistant", "content": None if call else "ok"}
            if tc:
                message["tool_calls"] = [{k: v for k, v in t.items() if k != "index"} for t in tc]
            return self.send(200, json.dumps(dict(base, object="chat.completion", usage=usage,
                                                  choices=[{"index": 0, "message": message, "finish_reason": finish}])))
        first = {"role": "assistant", "tool_calls": tc} if tc else {"role": "assistant", "content": "ok"}
        chunks = [dict(base, object="chat.completion.chunk", choices=[{"index": 0, "delta": first, "finish_reason": None}]),
                  dict(base, object="chat.completion.chunk", choices=[{"index": 0, "delta": {}, "finish_reason": finish}],
                       usage=usage)]
        return self.send(200, "".join(f"data: {json.dumps(c)}\n\n" for c in chunks) + "data: [DONE]\n\n",
                         "text/event-stream")


if __name__ == "__main__":
    os.makedirs(LOG, exist_ok=True)
    port = int(sys.argv[sys.argv.index("--port") + 1]) if "--port" in sys.argv else 8766
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
