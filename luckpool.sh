#!/bin/bash

# Color Variables
CYAN="\033[0;36m"
NC="\033[0m" # No Color
INFO="\033[0;32m"
ERROR="\033[0;31m"
SUCCESS="\033[0;32m"
WARN="\033[0;33m"

# Display a message after logo
echo -e "${CYAN}🎉 Displaying Aniani!!! ${NC}"

# Display logo directly from URL
echo -e "${CYAN}✨ Displaying logo... ${NC}"
wget -qO- https://raw.githubusercontent.com/Chupii37/Chupii-Node/refs/heads/main/Logo.sh | bash

# Update and upgrade system packages
echo -e "${INFO}🔄 Updating and upgrading packages... ${NC}"
sudo apt update && sudo apt upgrade -y

# Check if Docker is installed
echo -e "${INFO}🔍 Checking Docker installation... ${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${ERROR}🚫 Docker not found. Installing Docker... ${NC}"
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    echo -e "${SUCCESS}✔️ Docker successfully installed! ${NC}"
else
    echo -e "${SUCCESS}✔️ Docker is already installed. ${NC}"
fi

# Clean up unnecessary packages
echo -e "${INFO}🧹 Cleaning up unnecessary packages... ${NC}"
sudo apt-get autoremove -y
sudo apt-get clean
echo -e "${SUCCESS}✅ Unnecessary packages removed! ${NC}"

# Prompt user to enter wallet address
echo -e "${CYAN}💸 Enter your wallet address: ${NC}"
read address

# Choose server pool
echo -e "${CYAN}🌐 Choose your server pool: ${NC}"
echo "a. NORTH AMERICA"
echo "b. EUROPE"
echo "c. ASIA-PACIFIC"
read pool_choice

case $pool_choice in
    a) pool="na.luckpool.net" ;;
    b) pool="eu.luckpool.net" ;;
    c) pool="ap.luckpool.net" ;;
    *) echo -e "${ERROR}🚫 Invalid choice, exiting... ${NC}" && exit 1 ;;
esac

# Prompt user to enter worker name
echo -e "${CYAN}🧑‍💻 Enter your worker name: ${NC}"
read worker_name

# Ask for CPU usage
echo -e "${CYAN}💻 Enter the number of CPUs you want to use (example: 2 for 2 CPUs): ${NC}"
read cpu_count
cpu_count=${cpu_count:-1}  # Default to 1 if empty
if ! [[ "$cpu_count" =~ ^[0-9]+$ ]]; then
    echo -e "${ERROR}🚫 Invalid input for CPU count. Please enter a number. ${NC}"
    exit 1
fi

cpu_devices=""
for ((i=0; i<cpu_count; i++)); do
    cpu_devices="--cpu $i $cpu_devices"
done

# Choose port
echo -e "${CYAN}🔌 Choose a port to use: ${NC}"
echo "a. 3956"
echo "b. 3957"
echo "c. 3960"
read port_choice

case $port_choice in
    a) port="3956" ;;
    b) port="3957" ;;
    c) port="3960" ;;
    *) echo -e "${ERROR}🚫 Invalid choice, exiting... ${NC}" && exit 1 ;;
esac

# Choose mode (regular or hybrid)
echo -e "${CYAN}⚙️ Choose mode: ${NC}"
echo "a. Regular"
echo "b. Hybrid"
read mode

case $mode in
    a) mode="X" ;;
    b) mode="hybrid" ;;
    *) echo -e "${ERROR}🚫 Invalid mode choice, exiting... ${NC}" && exit 1 ;;
esac

# Check if directory exists, create if not
echo -e "${INFO}📂 Checking directory... ${NC}"
if [ -d "luckpool-docker" ]; then
  echo -e "${INFO}📂 Directory 'luckpool-docker' already exists. ${NC}"
else
  mkdir luckpool-docker
  echo -e "${SUCCESS}✅ Directory 'luckpool-docker' created successfully! ${NC}"
fi

# Change to the directory
cd luckpool-docker

# Get public IP address
public_ip=$(curl -s ifconfig.me)
if [ -z "$public_ip" ]; then
  echo -e "${ERROR}🚫 Failed to retrieve public IP address. Exiting. ${NC}"
  exit 1
fi

# Create Dockerfile with user input
echo -e "${INFO}📝 Creating Dockerfile... ${NC}"
cat <<EOL > Dockerfile
# Using the latest Ubuntu as the base image
FROM ubuntu:22.04

# Install necessary tools
RUN apt-get update && apt-get install -y \\
    wget \\
    tar 

WORKDIR /luckpool-docker

# Download and extract hellminer
RUN wget https://github.com/hellcatz/hminer/releases/download/v0.59.1/hellminer_linux64.tar.gz && \\
    tar -xvzf hellminer_linux64.tar.gz && \\
    chmod +x hellminer && \\
    rm hellminer_linux64.tar.gz

# Run the miner with provided parameters
CMD ["/bin/bash", "-c", "./hellminer -c stratum+tcp://$pool:$port -u $address.$worker_name -p $mode $cpu_devices"]
EOL

# Set container name and build the image
container_name="luckpool-docker"
echo -e "${INFO}⚙️ Building Docker image... ${NC}"
docker build -t $container_name .

# Run the Docker container
echo -e "${INFO}🚀 Running Docker container... ${NC}"
docker run -d --name $container_name --restart unless-stopped -v /usr/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu $container_name

# Success message with emojis
echo -e "${SUCCESS}🎉🚀✨ Your Docker container is now running with automatic restart enabled! ${NC}"
echo -e "${INFO}🔍 To view the logs in real-time, run the following command: ${NC}"
echo -e "${INFO}docker logs -f $container_name ${NC}"
