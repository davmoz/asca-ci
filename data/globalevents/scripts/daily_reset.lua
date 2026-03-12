-- Daily Reset Event
-- Runs at midnight to reset daily limits and check streak expiry

function onTime(interval)
	print(">> Daily reset event triggered")

	-- Reset is handled per-player on login via storage values
	-- This event logs the reset for monitoring
	local resetTime = os.date("%Y-%m-%d %H:%M:%S")
	print(">> Daily limits reset at " .. resetTime)

	return true
end
