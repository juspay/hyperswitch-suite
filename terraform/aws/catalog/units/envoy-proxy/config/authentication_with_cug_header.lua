--[[
  = Proxy Authentication Layer

  This layer is responsible for authenticating the requests on proxy level and
  then forwarding the requests to the upstream servers.

  == Types of Authentication

  The request could be of the following types:

  API Key Authentication::
    The request is authenticated using the API key provided in the request headers. The API key is present in the `+api-key+` header.

  JWT Authentication::
    The request is authenticated using the JWT token provided in the request headers. The JWT token is present in the `+Authorization+` header or `+Cookie+` header.

  === API Key Authentication

  The API key is present in the `+api-key+` header. The API key is used to authenticate the request. To authenticate the request using the API key, the following steps are performed:
  . The API key is extracted from the request headers.
  . The API key is validated by calling the decision service.
  . If the API key is valid, the request is forwarded to the upstream server and the details returned by the decision service are added to the request headers.
  . If the API key is invalid, the request is rejected with a `+401 Unauthorized+` status code.

--]]

local rapidjson = require("rapidjson")
local http = require("socket.http")
local ltn12 = require("ltn12")


--- @alias api_key_data { type: "api_key"|"publishable_key"|"admin_api_key", merchant_id: string | nil, key_id: string | nil }
--- @enum consts
local consts = {
  -- configuration
  BASE_URL = "http://auth-proxy.hyperswitch.internal",
  ENDPOINT = "/decision",
  METHOD = "POST",

  UNAUTHORIZED_RESPONSE = "401 Unauthorized",
  DEFAULT_TENANT = "hyperswitch",



  -- query headers
  API_KEY_HEADER = "api-key",
  JWT_HEADER = "authorization",
  COOKIE_HEADER = "cookie",
  DELIMITER = ";",
  COOKIE_KEY = "login_token",
  CACHE_EXPIRY = 3600,
  TENANT_ID_HEADER = "x-tenant-id",


  -- append headers
  MERCHANT_ID_HEADER = "x-merchant-id",
  KEY_ID_HEADER = "x-key-id",
  ORG_ID_HEADER = "x-org-id",
  AUTH_TYPE_HEADER = "x-auth-type",
  CHECKSUM_HEADER = "x-checksum",
  CUG_USER_HEADER = "x-cug-user",

}



--- API Key Cache (Not Used)
--- The cache is used to store the API key data for a certain period of time. This improves the performance of the system by reducing the number of calls to the decision service.
---
--- @alias metadata { created_at: number }
--- @type table<string, api_key_data | metadata>
local API_KEY_CACHE = {}


--- @param api_key string
--- @return api_key_data | nil
local function lookup_cache(api_key)
  local data = API_KEY_CACHE[api_key]

  if (data ~= nil) then
    if (data["created_at"] + consts.CACHE_EXPIRY < os.time()) then
      API_KEY_CACHE[api_key] = nil
      return nil
    end

    return {
      merchant_id = data["merchant_id"]
    }
  end
end

--- @param api_key string
--- @param data api_key_data
--- @return nil
local function populate_cache(api_key, data)
  API_KEY_CACHE[api_key] = {
    merchant_id = data["merchant_id"],
    created_at = os.time()
  }
end


--- Identifies the request based on the headers. It tries to identify if the request has:
--- 1. API Key
--- 2. JWT Token
--- 3. No Auth
--- @param headers table: The headers of the request
--- @alias auth_type
--- | "api_key"
--- | "jwt"
--- | "no_auth"
--- @return auth_type: The type of authentication the request has
local function identify_request(headers)
  local api_key = headers:get(consts.API_KEY_HEADER);

  if (api_key ~= nil) then
    return "api_key"
  end

  local jwt = headers:get(consts.JWT_HEADER);

  if (jwt ~= nil) then
    return "jwt"
  end

  local cookies = headers:get(consts.COOKIE_HEADER);

  if (cookies ~= nil) then
    for cookie in string.gmatch(cookies, "([^" .. consts.DELIMITER .. "]+)") do
      local ckey, _ = string.match(cookie, "(%w+)=([^;]+)")
      if (ckey == consts.COOKIE_KEY) then
        return "jwt"
      end
    end
  end

  return "no_auth"
end

--- @param api_key string | nil
--- @param tenant string | nil
--- @param loggers { info: fun(string), error: fun(string), critical: fun(string) }
--- @return { identifiers: api_key_data, checksum: string, is_cug: boolean } | nil
local function call_decision_service(api_key, tenant, loggers)
  if (api_key == nil) then
    loggers.error("API Key not found")
    return nil
  end

  local url = consts.BASE_URL .. consts.ENDPOINT
  local headers = {
    ["content-type"] = "application/json"
  }

  local raw_body = {
    type = "api_key",
    tag = tenant or consts.DEFAULT_TENANT,
    api_key = api_key,
  }

  local body = rapidjson.encode(raw_body)
  local response_body = {}

  local _, code, _, _ = http.request({
    url = url,
    method = consts.METHOD,
    headers = headers,
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(response_body)
  })

  loggers.info("[" .. code .. " OK] Decision Service")

  if (code == 200) then
    local response = rapidjson.decode(table.concat(response_body))

    if (response.decision == "allow") then
      return {
        identifiers = response.identifiers,
        checksum = response.checksum,
        is_cug = response.is_cug or false
      }
    else
      return nil
    end
  else
  end
end

--- @param request table : The request object
--- @param data { identifiers: api_key_data, checksum: string, is_cug: boolean } : The data returned by the decision service
function attach_headers(request, data)
  local request_id = request:headers():get("x-request-id")

  if request_id ~= nil then
    request:logInfo("request-id: " .. request_id .. " | merchant-id: " .. data.identifiers.merchant_id)
  end

  request:logInfo("")

  if data.is_cug == true then
      request:headers():replace(consts.CUG_USER_HEADER, "true")
      request:logInfo("CUG merchant identified by decision service")
  end

  if data.identifiers.type == "api_key" then
    if data.identifiers.merchant_id ~= nil then
      request:headers():add(consts.MERCHANT_ID_HEADER, data.identifiers.merchant_id)
    end
    if data.identifiers.key_id ~= nil then
      request:headers():add(consts.KEY_ID_HEADER, data.identifiers.key_id)
    end
  elseif data.identifiers.type == "publishable_key" then
    if data.identifiers.merchant_id ~= nil then
      request:headers():add(consts.MERCHANT_ID_HEADER, data.identifiers.merchant_id)
    end
  end

  request:headers():add(consts.AUTH_TYPE_HEADER, data.identifiers.type)
  request:headers():add(consts.CHECKSUM_HEADER, data.checksum)
end

function mark_unauthorized(request)
  request:respond({
    [":status"] = "401",
  }, consts.UNAUTHORIZED_RESPONSE)
end

function envoy_on_request(request)

  request:headers():remove("x-key-id")
  request:headers():remove("x-auth-type")
  request:headers():remove("x-checksum")
  request:logInfo("Headers Sanitized")

  local tenant_id_header = request:headers():get("x-tenant-id")
  if tenant_id_header == nil then
    request:headers():add("x-tenant-id", "public")
    request:logInfo("Tenant ID not found, setting to public")
  end

  local auth_type = identify_request(request:headers());

  request:logInfo("Auth Type: " .. auth_type)

  if (auth_type == "no_auth") then
    -- mark_unauthorized(request)
    return
  elseif (auth_type == "jwt") then
    return
  end

  local api_key = request:headers():get(consts.API_KEY_HEADER)
  local tenant = request:headers():get(consts.TENANT_ID_HEADER) or "public"
  local lookup = call_decision_service(api_key, tenant, {
    info = function(value) request:logInfo(value) end,
    error = function(value) request:logErr(value) end,
    critical = function(value) request:logCritical(value) end,
  })

  if (lookup == nil) then
    request:logErr("Unauthorized")
    -- mark_unauthorized(request)
    return
  end
  request:logInfo("Authorized")

  attach_headers(request, lookup)
end
