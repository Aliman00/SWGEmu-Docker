# SWGEmu Docker Setup

This project provides a Dockerized environment to build and run an SWGEmu (Star Wars Galaxies Emulator) Core3 server. It uses Nix within the Docker image for a reproducible build and runtime environment.

## Prerequisites

*   **Docker**: Ensure Docker is installed and running on your system. [Install Docker](https://docs.docker.com/get-docker/)
*   **Docker Compose**: Ensure Docker Compose is installed. It's often included with Docker Desktop. [Install Docker Compose](https://docs.docker.com/compose/install/)

Nix is **not** required on your host system to build or run the server using Docker, as it's utilized within the Docker image itself.

## Setup and Installation

1.  **Clone the Repository (if you haven't already):**
    ```bash
    git clone https://github.com/Aliman00/SWGEmu-Docker
    cd SWGEmu-Docker
    ```

2.  **Place SWG TRE Files:**
    *   You need the original Star Wars Galaxies client TRE (Tree) files.
    *   Place your `*.tre` files into the `tre/` directory in this project. Refer to [tre/info.txt](tre/info.txt) for more details.

3.  **Review Configuration (Optional):**
    *   The main server configuration is located in [conf/config.lua](conf/config.lua).
    *   This file is mounted into the Docker container. You can modify it to change server settings (e.g., database credentials if you use an external database, galaxy name, etc.).
    *   The default `DBHost` in [conf/config.lua](conf/config.lua) is `127.0.0.1`. If you plan to use the optional MySQL service defined in [docker-compose.yaml](docker-compose.yaml), you would change `DBHost` to `mysql` (the service name).

## Running the Server

1.  **Build and Start the Docker Container:**
    *   Navigate to the root directory of this project (where [docker-compose.yaml](docker-compose.yaml) is located).
    *   Run the following command:
        ```bash
        docker compose up -d --build
        ```
    *   This command will:
        *   Build the Docker image using the [Dockerfile](Dockerfile). This involves fetching dependencies with Nix (inside the build container) and compiling SWGEmu Core3. This step can take a significant amount of time, especially on the first run.
        *   Start the `swgemu-core3` service in detached mode (`-d`). The server is started using `nix-shell` *inside* the running container as per the `ENTRYPOINT` in the [Dockerfile](Dockerfile).

2.  **Check Logs:**
    *   To view the server logs:
        ```bash
        docker-compose logs -f swgemu-core3
        ```
    *   Logs are also stored in a Docker volume named `swgemu-logs`, which is mapped from `/app/Core3/MMOCoreORB/bin/log` inside the container.

3.  **Accessing the Server:**
    The following ports are exposed by default (as defined in [docker-compose.yaml](docker-compose.yaml)):
    *   **Login Server:** `44453`
    *   **Zone Server:** `44454`
    *   **Ping Server:** `44455` (Note: [conf/config.lua](conf/config.lua) defines `PingPort` as `44462` internally, but [docker-compose.yaml](docker-compose.yaml) maps host `44455` to container `44455`. The `EXPOSE` in [Dockerfile](Dockerfile) and the `ENTRYPOINT` starting `./core3` will use the ports defined in `config.lua` unless overridden by command-line arguments to `core3`, which is not the case here. The `StatusPort` in `config.lua` is `44455`. This might need clarification or adjustment in your port mappings or config if `44455` is intended for Ping or Status).
    *   **Status Server:** `44463`
    *   **Admin Server:** `44443`

    You will need a compatible SWG client configured to connect to your server's IP address and the Login Server port.

## Stopping the Server

1.  **Stop and Remove Containers:**
    ```bash
    docker compose down
    ```
    This will stop and remove the containers. Data stored in Docker volumes (`swgemu-logs`, `swgemu-db`) will persist unless you explicitly remove the volumes (e.g., `docker-compose down -v`).

## Optional: Local Development Environment (Using Nix Shell on Host)

This section is for developers who wish to build or work on the Core3 source code directly on their host machine, outside of the Docker container. **For this specific scenario, Nix is required on your host system.**

1.  **Install Nix (if not already installed for local development):**
    *   Follow the instructions at [Install Nix](https://nixos.org/download.html).
    *   You might need to enable flakes and the new nix command interface if not enabled by default:
        ```bash
        echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
        ```
        Restart your terminal or source your shell configuration after this change.

2.  **Enter the Nix Shell:**
    Navigate to the project root and run:
    ```bash
    nix-shell
    ```
    This will drop you into a shell with all the dependencies defined in [shell.nix](shell.nix) available.

3.  **Clone Core3 (if not already present):**
    If the `Core3` directory doesn't exist:
    ```bash
    git clone --recursive https://github.com/swgemu/Core3.git Core3
    ```

4.  **Build Core3 Locally:**
    The [shell.nix](shell.nix) provides a helper function `build-core3`.
    *   From the project root (where `shell.nix` is), ensure you are in the Nix shell.
    *   Run the build command (it will navigate into `Core3/MMOCoreORB`):
        ```bash
        build-core3
        ```
    This will compile the server. The binaries will be located in `Core3/MMOCoreORB/bin/`.

## Optional: Using an External MySQL Database

The [docker-compose.yaml](docker-compose.yaml) includes a commented-out section for a MySQL service. If you wish to use it:

1.  **Uncomment the `mysql` service** in [docker-compose.yaml](docker-compose.yaml).
2.  **Uncomment the `mysql-data` volume** in [docker-compose.yaml](docker-compose.yaml).
3.  **Update `DBHost` in [conf/config.lua](conf/config.lua):**
    Change `DBHost = "127.0.0.1"` to `DBHost = "mysql"`.
4.  **Database Initialization (Optional):**
    *   If you have SQL initialization scripts (e.g., for creating the database schema or initial data), place them in a directory (e.g., `conf/mysql-init/`) and uncomment/adjust the volume mount: `- ./conf/mysql-init:/docker-entrypoint-initdb.d:ro` in the `mysql` service definition.
5.  **Start services:**
    ```bash
    docker-compose up -d --build
    ```

## Troubleshooting

*   **Build Failures (Docker):** Check the output from `docker-compose up --build` for specific error messages. Ensure Docker and Docker Compose are correctly installed and configured.
*   **Port Conflicts:** If other services on your machine use the same ports, you might need to change the port mappings in [docker-compose.yaml](docker-compose.yaml) (e.g., change `"44453:44453"` to `"some_other_port:44453"`).
*   **TRE File Issues:** Double-check that all required TRE files are present in the `tre/` directory and that their names match those expected by the server (see [conf/config.lua](conf/config.lua)).
*   **Ping/Status Port Mismatch**: Review the port mappings in [docker-compose.yaml](docker-compose.yaml) against the `PingPort` and `StatusPort` in [conf/config.lua](conf/config.lua) and the `EXPOSE` instruction in the [Dockerfile](Dockerfile). The `docker-compose.yaml` maps host port `44455` to container port `44455`. In [conf/config.lua](conf/config.lua), `PingPort` is `44462` and `StatusPort` is `44455`. Ensure the client is configured to connect to the host ports defined in `docker-compose.yaml`.