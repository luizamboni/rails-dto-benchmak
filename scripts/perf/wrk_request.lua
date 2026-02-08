-- Env-driven wrk script for POST/PUT/etc.
-- Supports:
--   WRK_METHOD (default POST)
--   WRK_BODY (default empty)
--   WRK_HEADERS (format: "Header: Value;Other: Value")

local function split_headers(header_str)
  local headers = {}
  if not header_str or header_str == "" then
    return headers
  end

  for pair in string.gmatch(header_str, "([^;]+)") do
    local name, value = pair:match("^%s*([^:]+)%s*:%s*(.-)%s*$")
    if name and value then
      headers[name] = value
    end
  end

  return headers
end

local method = os.getenv("WRK_METHOD") or "POST"
local base_body = os.getenv("WRK_BODY") or ""
local headers = split_headers(os.getenv("WRK_HEADERS"))

wrk.method = method
wrk.body = base_body
wrk.headers = headers

local seq = 0
local thread_tag = "t0"
local email_pattern = '"email"%s*:%s*"[^"]*"'

local function endpoint_version()
  local path = wrk.path or ""
  return path:match("/api/(v%d+)/") or path:match("/api/(v%d+)") or "v?"
end

-- Try to get a stable per-thread tag to avoid cross-thread collisions.
-- Falls back to a parsed pointer-like suffix from tostring(thread).
function setup(thread)
  local ok, id = pcall(function()
    if type(thread) == "table" then
      if thread.id ~= nil then
        return tostring(thread.id)
      end
      if thread.get then
        local v = thread:get("id")
        if v ~= nil then
          return tostring(v)
        end
      end
    end
    return nil
  end)

  if ok and id and id ~= "" then
    thread_tag = id
    return
  end

  local s = tostring(thread)
  local hex = s:match("0x([%x]+)")
  if hex then
    thread_tag = hex
  end
end

local function build_body()
  seq = seq + 1
  local ts_base = os.date("!%Y%m%dT%H%M%S")
  local micros = math.floor((os.clock() * 1000000) % 1000000)
  local ts = string.format("%s.%06dZ", ts_base, micros)
  local v = endpoint_version()
  local email = string.format("perf+%s-%s-%s-%d@example.com", v, ts, thread_tag, seq)
  if base_body ~= "" and base_body:match(email_pattern) then
    return base_body:gsub(email_pattern, string.format('"email":"%s"', email))
  end
  return base_body
end

request = function()
  local body = build_body()
  return wrk.format(nil, nil, nil, body)
end
