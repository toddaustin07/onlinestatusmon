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

  Dependency:  Forwarding Edge Bridge Server running on the LAN

--]]

-- Edge libraries
local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local cosock = require "cosock"                                         -- for time only
local socket = require "cosock.socket"                                  -- for time only
local log = require "log"
local json = require "dkjson"

local comms = require "comms"

-- Custom Capabiities
local cap_status = capabilities["partyvoice23922.onlinestatus"]
local cap_createdev = capabilities["partyvoice23922.createanother"]

-- Module variables
local thisDriver = {}
local initialized = false


local function validate_address(lanAddress)

  local valid = true
  
  local ip = lanAddress:match('^(%d.+):')
  local port = tonumber(lanAddress:match(':(%d+)$'))
  
  if ip then
    local chunks = {ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")}
    if #chunks == 4 then
      for _, v in pairs(chunks) do
        if tonumber(v) > 255 then 
          valid = false
          break
        end
      end
    else
      valid = false
    end
  else
    valid = false
  end
  
  if port then
    if type(port) == 'number' then
      if (port < 1) or (port > 65535) then 
        valid = false
      end
    else
      valid = false
    end
  else
    valid = false
  end
  
  if valid then
    return ip, port
  else
    return nil
  end
      
end


local function validate_bridge(device)

  if validate_address(device.preferences.bridgeaddr) then
    device:set_field('validbridge', true)
  else
    device:set_field('validbridge', false)
  end

end

local function create_device(driver)

  local MFG_NAME = 'SmartThings Community'
  local MODEL = 'devstatmon'
  local VEND_LABEL = 'Online Status Monitor'
  local ID = 'devstatmon_' .. socket.gettime()
  local PROFILE = 'devstatmon.v1b'

  log.info (string.format('Creating new device: label=<%s>, id=<%s>', VEND_LABEL, ID))

  local create_device_msg = {
                              type = "LAN",
                              device_network_id = ID,
                              label = VEND_LABEL,
                              profile = PROFILE,
                              manufacturer = MFG_NAME,
                              model = MODEL,
                              vendor_provided_label = VEND_LABEL,
                            }
                      
  assert (driver:try_create_device(create_device_msg), "failed to create device")

end


local function do_poll(device)

  if device:get_field('validbridge') == true then
  
    local response = comms.get_status(device)
    
    if response then
    
      local jsondata, pos, err = json.decode (response, 1, nil)
      if err then
        log.error ("JSON decode error:", err)
        return nil
      end
      
      log.debug (string.format('Returned state=%s for device %s', jsondata.state, device.label))

      device:emit_event(cap_status.status(string.lower(jsondata.state)))
    
    end
  
  end

end


local function stop_polling(device)

  local polltimer = device:get_field('polltimer')
  if polltimer then
    thisDriver:cancel_timer(polltimer)
  end

end


local function start_polling(device)

  stop_polling(device)

  local polltimer = device.thread:call_on_schedule(device.preferences.interval*60, 
                                                    function()
                                                      do_poll(device)
                                                    end )
          
  device:set_field('polltimer', polltimer)

end


-----------------------------------------------------------------------
--										COMMAND HANDLERS
-----------------------------------------------------------------------

local function handle_stockrefresh(driver, device, command)

  log.info ('Stock refresh requested; command:', command.command)

  do_poll(device)
  
end

local function handle_createdev(driver, device, command)

	log.info ('Create additional device requested')

	create_device(driver)

end


------------------------------------------------------------------------
--                REQUIRED EDGE DRIVER HANDLERS
------------------------------------------------------------------------

-- Lifecycle handler to initialize existing devices AND newly discovered devices
local function device_init(driver, device)
  
    log.debug(device.id .. ": " .. device.device_network_id .. "> INITIALIZING")
  
    validate_bridge(device)
    
    start_polling(device)
  
    initialized = true
    
    log.debug('Exiting device initialization')
end


-- Called when device was just created in SmartThings
local function device_added (driver, device)

  log.info(device.id .. ": " .. device.device_network_id .. "> ADDED")
  
  device:emit_event(cap_status.status('offline'))
  
end


-- Called when SmartThings thinks the device needs provisioning
local function device_doconfigure (_, device)

  log.info ('Device doConfigure lifecycle invoked')

end


-- Called when device was deleted via mobile app
local function device_removed(driver, device)
  
  log.warn(device.id .. ": " .. device.device_network_id .. "> removed")

  stop_polling(device)

  local device_list = driver:get_devices()
  if #device_list == 0 then
    log.warn ('All devices removed')
    initialized = false
  end
  
end


local function handler_driverchanged(driver, device, event, args)

  log.debug ('*** Driver changed handler invoked ***')

end


local function shutdown_handler(driver, event)

  log.warn('Driver shutdown')
  local device_list = driver:get_devices()
  for _, device in ipairs(device_list) do
    stop_polling(device)
  end
  log.info('\tAll polling terminated')
end


local function handler_infochanged (driver, device, event, args)

  log.debug ('Info changed handler invoked')

  -- Did preferences change?
  if args.old_st_store.preferences then
  
    if args.old_st_store.preferences.bridgeaddr ~= device.preferences.bridgeaddr then
      log.info ('Bridge address changed to: ', device.preferences.bridgeaddr)
      validate_bridge(device)
      
    elseif args.old_st_store.preferences.interval ~= device.preferences.interval then
      log.info ('Polling Interval changed to: ', device.preferences.interval, type(device.preferences.interval))
      start_polling(device)
    end
  end
end


-- Create Initial Device
local function discovery_handler(driver, _, should_continue)
  
  log.debug("Device discovery invoked")
  
  if not initialized then
    create_device(driver)
  end
  
  log.debug("Exiting discovery")
  
end


-----------------------------------------------------------------------
--        DRIVER MAINLINE: Build driver context table
-----------------------------------------------------------------------
thisDriver = Driver("thisDriver", {
  discovery = discovery_handler,
  lifecycle_handlers = {
    init = device_init,
    added = device_added,
    driverSwitched = handler_driverchanged,
    infoChanged = handler_infochanged,
    doConfigure = device_doconfigure,
    removed = device_removed
  },
  driver_lifecycle = shutdown_handler,
  capability_handlers = {
    [cap_createdev.ID] = {
      [cap_createdev.commands.push.NAME] = handle_createdev,
    },
    [capabilities.refresh.ID] = {
      [capabilities.refresh.commands.refresh.NAME] = handle_stockrefresh,
    },
  }
})

log.info ('Online Device Status Monitor v0.1 Started')


thisDriver:run()
