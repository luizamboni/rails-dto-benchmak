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
local body = os.getenv("WRK_BODY") or ""
local headers = split_headers(os.getenv("WRK_HEADERS"))

wrk.method = method
wrk.body = body
wrk.headers = headers

request = function()
  return wrk.format(nil, nil, nil, body)
end
