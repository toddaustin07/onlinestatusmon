--[[
  Copyright 2021 Todd Austin

  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
  except in compliance with the License. You may obtain a copy of the License at:

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software distributed under the
  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
  either express or implied. See the License for the specific language governing permissions
  and limitations under the License.


  DESCRIPTION
  
  Edge Driver for monitoring online status of SmartThings devices; uses SmartThings REST API via edge bridge server or other proxy

  Module:  Perform polling to SmartThings API

--]]

local cosock = require "cosock"                                         -- for time only
local socket = require "cosock.socket"                                  -- for time only
local http = cosock.asyncify "socket.http"
http.TIMEOUT = 8

local ltn12 = require "ltn12"
local log = require "log"



-- Send http or https request and emit response, or handle errors
local function issue_request(req_method, req_url, sendbody)

  local responsechunks = {}
  
  local content_length = 0
  if sendbody then
    content_length = string.len(sendbody)
  end
  
  local sendheaders = {
                        ["Acccept"] = '*/*',
                        ["Content-Length"] = content_length,
                      }
  
  local protocol = req_url:match('^(%a+):')
  local body, code, headers, status
  
  if protocol == 'https' then
  
    body, code, headers, status = https.request{
      method = req_method,
      url = req_url,
      headers = sendheaders,
      protocol = "any",
      options =  {"all"},
      verify = "none",
      source = ltn12.source.string(sendbody),
      sink = ltn12.sink.table(responsechunks)
     }

  else
    body, code, headers, status = http.request{
      method = req_method,
      url = req_url,
      headers = sendheaders,
      source = ltn12.source.string(sendbody),
      sink = ltn12.sink.table(responsechunks)
     }
  end

  local response = table.concat(responsechunks)
  
  log.info(string.format("response code=<%s>, status=<%s>", code, status))

  local httpcode_str
  local httpcode_num
  protocol = string.upper(protocol)
  
  if type(code) == 'number' then
    httpcode_num = code
  else
    httpcode_str = code
  end
  
  
  if (httpcode_num == 200) then
    return response
      
  else
    return
  end
    
end


local function get_status(device)

  local proxy
  
  if device.preferences.proxytype == 'edge' then

    proxy = "http://" .. device.preferences.bridgeaddr .. '/api/forward?url='

  elseif device.preferences.proxytype == 'custom' then
  
    proxy = device.preferences.customprefix
    
  end
  
  local url = proxy .. 'https://api.smartthings.com/v1/devices/' .. device.preferences.deviceid .. '/health'
  
  return issue_request("GET", url, nil)

end

return  {

					get_status = get_status,
					
				}
