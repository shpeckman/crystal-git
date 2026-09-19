# makefile

.PHONY: all test clean check-deps

all: check-deps test

check-deps:
	@echo "Checking system dependencies..."
	@command -v crystal >/dev/null 2>&1 || { echo >&2 "Error: 'crystal' is required but not installed. Please install it (e.g., https://crystal-lang.org/install/)."; exit 1; }
	@command -v shards >/dev/null 2>&1 || { echo >&2 "Error: 'shards' is required but not installed."; exit 1; }
	@command -v pkg-config >/dev/null 2>&1 || { echo >&2 "Error: 'pkg-config' is required to check C dependencies. Please install it."; exit 1; }
	@pkg-config --exists libgit2 || { \
		echo >&2 "Error: 'libgit2' is missing."; \
		OS=$$(uname -s); \
		if [ "$$OS" = "Darwin" ]; then \
			echo >&2 "Please install it using: brew install libgit2"; \
		elif [ "$$OS" = "Linux" ] && [ -f /etc/os-release ]; then \
			DISTRO=$$(grep -E '^(ID|ID_LIKE)=' /etc/os-release | cut -d= -f2 | tr -d '"' | tr '\n' ' '); \
			if echo "$$DISTRO" | grep -q -E 'debian|ubuntu'; then \
				echo >&2 "Please install it using: sudo apt-get install libgit2-dev"; \
			elif echo "$$DISTRO" | grep -q -E 'fedora|rhel|centos|rocky|almalinux'; then \
				echo >&2 "Please install it using: sudo dnf install libgit2-devel"; \
			elif echo "$$DISTRO" | grep -q -E 'arch|manjaro'; then \
				echo >&2 "Please install it using: sudo pacman -S libgit2"; \
			elif echo "$$DISTRO" | grep -q -E 'alpine'; then \
				echo >&2 "Please install it using: sudo apk add libgit2-dev"; \
			else \
				echo >&2 "Please install the libgit2 development package for your distribution."; \
			fi; \
		else \
			echo >&2 "Please install the libgit2 development package for your system."; \
		fi; \
		exit 1; \
	}
	@echo "All dependencies are satisfied."

test: check-deps
	crystal spec

bindings: check-deps
	crystal spec spec/libgit2_spec.cr

stream: check-deps
	crystal spec spec/stream_spec.cr spec/commands_spec.cr spec/rollback_spec.cr

clean:
	rm -rf tmp_*