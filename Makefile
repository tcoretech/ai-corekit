install:
	@echo "Installing launchkit to /usr/local/bin/launchkit..."
	@ln -sf $(PWD)/launchkit.sh /usr/local/bin/launchkit
	@chmod +x /usr/local/bin/launchkit
	@echo "Done. You can now run 'launchkit <command>'."

uninstall:
	@echo "Removing launchkit from /usr/local/bin/launchkit..."
	@rm -f /usr/local/bin/launchkit
	@echo "Done."
