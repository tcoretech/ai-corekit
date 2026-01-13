install:
	@echo "Installing corekit to /usr/local/bin/corekit..."
	@ln -sf $(PWD)/corekit.sh /usr/local/bin/corekit
	@chmod +x /usr/local/bin/corekit
	@echo "Done. You can now run 'corekit <command>'."

uninstall:
	@echo "Removing corekit from /usr/local/bin/corekit..."
	@rm -f /usr/local/bin/corekit
	@echo "Done."
