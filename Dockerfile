# Use nixos/nix:latest as base image
FROM nixos/nix:latest

# Enable flakes and nix-command
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# Set working directory
WORKDIR /app

# Copy the shell.nix file
COPY shell.nix .

# Clone the SWGEmu Core3 repository to create the expected directory structure
# Clone to "Core3" subdirectory so build-core3 can find it
RUN nix-shell shell.nix --run "git clone --recursive https://github.com/swgemu/Core3.git Core3"

# Now we're in /app and have /app/Core3 directory structure that build-core3 expects
# Build the project using the build-core3 function from shell.nix
RUN nix-shell shell.nix --run "build-core3"

# Create startup script
RUN printf '#!/bin/bash\n\
set -e\n\
\n\
# Navigate to the binary directory\n\
cd /app/Core3/MMOCoreORB/bin\n\
\n\
# Start Core3 server directly\n\
exec nix-shell /app/shell.nix --run "./core3"\n' > /app/start.sh

RUN chmod +x /app/start.sh

# Expose the standard Core3 ports
EXPOSE 44453 44454 44455 44463 44443

# Set the entrypoint
ENTRYPOINT ["/app/start.sh"]