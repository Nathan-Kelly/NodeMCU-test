available = {}			-- list of our APs, needed in other wifi files


--[[Requirements for an AP to be considered part of our network and available.  If set to
    nil or false the requirement is ignored (and all functions that check it will return true).

    Created because the selection of an appropriate AP may need to be more robust in future.]]
local minrssi = -70		-- minimum signal strength considered acceptable
local ssid_pattern = "riot%-waikato"
local bssidlist = nil	-- contains approved BSSIDs as keys with value true


--[[Checks if the bssid given is contained in bssidlist.  If bssidlist is nil, always returns true.]]
function bssidapproved(bssid)
    if bssidlist then
        return bssidlist[bssid]
    else
        return true
    end
end


--[[Checks that the given ssid matches the pattern.  If pattern is nil, always returns true.]]
function ssidpatternmatches(ssid)
    if ssid_pattern then
        return string.find(ssid, ssid_pattern)
    else
        --if there is no pattern provided, match all SSIDs
        return true
    end
end


--[[Checks that the given rssi is better than minrssi.  If minrssi is nil, always returns true.]]
function rssiacceptable(rssi)
    if minrssi then
        return tonumber(rssi) >= minrssi
    else
        return true
    end
end


--[[Checks that all requirements are met for the AP to considered in our network and
    available.]]
function apmatches(bssid, ssid, rssi, authmode, channel)
    if not bssidapproved(bssid) then
        return false
    end

    if not ssidpatternmatches(ssid) then
        return false
    end

    if not rssiacceptable(rssi) then
        print("Signal strength of "..ssid.." too low. ("..rssi..")")
        return false
    end

    return true
end


--[[Using the table provided to the do_onscancomplete callback function, find APs that match
    our network using the SSID pattern.  Does not include APs if their signal strength is too
    low.  Stores APs that match in the 'available' table with BSSID as the key.]]
function getmatchingaps(t)

    available = {}

    for bssid,v in pairs(t) do
        local ssid, rssi, authmode, channel = string.match(v, "([^,]+),([^,]+),([^,]+),([^,]*)")

        if apmatches(bssid, ssid, rssi, authmode, channel) then
            available[bssid] = ssid
        end
    end
end


--[[Chooses an available AP to connect this device to.  Current algorithm chooses a
    random AP out of those available.  If no AP is available, sets an alarm which will
    start another AP scan.
    ]]
function chooseavailableap()
    local apset = {}	-- an array of AP BSSIDs
    local count = 0

    --get list of BSSIDs from available (and count them)
    for bssid, ssid in pairs(available) do
        count = count + 1
        apset[count] = bssid
    end

    if count > 1 then
        --select randomly
        select = math.random(1, count)
    elseif count == 1 then
        --select only AP available
        select = 1
    elseif count == 0 then
        print("No RIOT access points found...")
        --start retry timer
        tmr.alarm(wifitmr, retryinterval, tmr.ALARM_SINGLE, wifiscan)
        wifiretries = wifiretries + 1
        return
    end

    print("Connecting to access point: "..available[apset[select]])
    print(wifi.sta.getconfig())

    --Connect if there is a valid AP available
    if select ~= nil then
        wifi.sta.config(available[apset[select]], password, 1, apset[select])
        wifi.sta.connect()
    end
end
