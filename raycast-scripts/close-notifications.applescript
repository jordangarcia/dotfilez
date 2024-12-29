#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title dismiss notifications
# @raycast.mode silent

# Optional parameters:
# @raycast.icon ❌

# Documentation:
# @raycast.author jordan_garcia
# @raycast.authorURL https://raycast.com/jordan_garcia

-- macOS 15 Sequoia
-- Set of close action phrases in multiple languages
property closeActionSet : {"Close", "Clear All", "Schließen", "Alle entfernen", "Cerrar", "Borrar todo", "¿¿", "¿¿¿¿", "Fermer", "Tout effacer", "¿¿¿¿¿¿¿", "¿¿¿¿¿¿¿¿ ¿¿¿", "¿¿¿¿¿", "¿¿¿ ¿¿¿¿", "Fechar", "Limpar tudo", "¿¿¿", "¿¿¿¿¿¿", "¿¿¿ ¿¿¿¿", "¿¿¿ ¿¿¿¿¿", "Zamknij", "Wyczy¿¿ wszystko"}

-- Function to perform close action on a given element
on closeNotification(elemRef)
	tell application "System Events"
		try
			set theActions to actions of elemRef
			repeat with act in theActions
				if description of act is in closeActionSet then
					perform act
					return true
				end if
			end repeat
		end try
	end tell
	return false
end closeNotification

-- Function to recursively search for and close notifications
on searchAndCloseNotifications(elemRef)
	tell application "System Events"
		-- If the element has subelements, search them first
		try
			set subElements to UI elements of elemRef
			repeat with subElem in subElements
				if my searchAndCloseNotifications(subElem) then
					return true
				end if
			end repeat
		end try
		
		-- Try to close the current element if it's a notification
		if my closeNotification(elemRef) then
			return true
		end if
	end tell
	return false
end searchAndCloseNotifications

-- Main script to clear notifications
on run
	tell application "System Events"
		if not (exists process "NotificationCenter") then
			log "NotificationCenter process not found"
			return
		end if
		
		tell process "NotificationCenter"
			if not (exists window "Notification Center") then
				log "Notification Center window not found"
				return
			end if
			
			set notificationWindow to window "Notification Center"
			
			-- Main loop to clear notifications
			repeat
				try
					if not my searchAndCloseNotifications(notificationWindow) then
						-- If no notifications were closed, we're done
						exit repeat
					end if
					
					-- Reduced delay to speed up the script
					delay 0.1
				on error errMsg
					-- If an error occurs, log it and exit the loop
					log "Error: " & errMsg
					exit repeat
				end try
			end repeat
		end tell
	end tell
end run
