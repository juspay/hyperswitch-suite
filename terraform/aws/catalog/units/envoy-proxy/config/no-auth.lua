local rapidjson = require("rapidjson")
local http = require("socket.http")
local ltn12 = require("ltn12")

--- @enum consts
local consts = {
  -- configuration
  BASE_URL = "http://auth-proxy.hyperswitch.internal",
  CUG_ENDPOINT = "/decision/cug",
  METHOD = "POST",

  -- query headers
  TENANT_ID_HEADER = "x-tenant-id",

  -- append headers
  CUG_USER_HEADER = "x-cug-user",
}

--- Extract merchant_id from URL paths
--- @param path string | nil
--- @return { merchant_id: string } | nil
local function get_merchant_id_from_path(path)
  if not path then return nil end

  -- /payments/{payment_id}/{merchant_id}/redirect/response/{connector}
  local merchant_id = path:match("^/payments/[^/]+/([^/]+)/redirect/response/")
  if merchant_id then return merchant_id end

  -- /payments/{payment_id}/{merchant_id}/redirect/complete/{connector}
  -- /payments/{payment_id}/{merchant_id}/redirect/complete/{connector}/{creds_identifier}
  merchant_id = path:match("^/payments/[^/]+/([^/]+)/redirect/complete/")
  if merchant_id then return merchant_id end

  -- /payments/{payment_id}/{merchant_id}/authorize/{connector}
  merchant_id = path:match("^/payments/[^/]+/([^/]+)/authorize/")
  if merchant_id then return merchant_id end

  -- /webhooks/relay/{merchant_id}/{connector_id}
  merchant_id = path:match("^/webhooks/relay/([^/]+)/")
  if merchant_id then return merchant_id end

  -- /webhooks/{merchant_id}/{connector_id}
  merchant_id = path:match("^/webhooks/([^/]+)/")
  if merchant_id then return merchant_id end

  -- /payments/redirect/{payment_id}/{merchant_id}/{attempt_id}
  merchant_id = path:match("^/payments/redirect/[^/]+/([^/]+)/")
  if merchant_id then return merchant_id end

  -- /payment_link/s/{merchant_id}/{payment_id}
  merchant_id = path:match("^/payment_link/s/([^/]+)/")
  if merchant_id then return merchant_id end

  -- /payment_link/status/{merchant_id}/{payment_id}
  merchant_id = path:match("^/payment_link/status/([^/]+)/")
  if merchant_id then return merchant_id end

  -- /payment_link/{merchant_id}/{payment_id}
  merchant_id = path:match("^/payment_link/([^/]+)/")
  if merchant_id then return merchant_id end

  return nil
end

--- Check if merchant is CUG
--- @param merchant_id string: The merchant ID to check for CUG status
--- @param request table: The request object for logging
--- @return boolean: true if merchant is part of CUG, false otherwise
local function check_cug_status(merchant_id, request)
  local url = consts.BASE_URL .. consts.CUG_ENDPOINT
  local body = rapidjson.encode({merchant_id = merchant_id})
  local response_body = {}

  local _, code = http.request({
    url = url,
    method = consts.METHOD,
    headers = {["content-type"] = "application/json"},
    source = ltn12.source.string(body),
    sink = ltn12.sink.table(response_body)
  })

  if code == 200 then
    local response = rapidjson.decode(table.concat(response_body))
    return response.is_cug
  end

  return false
end

function envoy_on_request(request)
  request:logInfo("No auth on-request")
  local tenant_id_header = request:headers():get("x-tenant-id")
  if tenant_id_header == nil then
    request:headers():add("x-tenant-id", "public")
    request:logInfo("Tenant ID not found, setting to public")
  end

  -- Check for CUG webhook/redirect paths
  local path = request:headers():get(":path")
  local merchant_id = get_merchant_id_from_path(path)

  if merchant_id then
    request:logInfo("Found merchant_id in path: " .. merchant_id)
    local is_cug = check_cug_status(merchant_id, request)

    if is_cug then
      request:headers():replace(consts.CUG_USER_HEADER, "true")
      request:logInfo("CUG merchant: " .. merchant_id)
    end
    return
  end
end
