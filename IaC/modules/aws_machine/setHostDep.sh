#!/bin/bash

set -e

DOCKER_USER="neeabhishek" 
DOCKER_PASS="pkhR0adlqx@123#" 

# Function to wait for APT locks to be released
wait_for_apt_lock() {
  echo "Checking for APT locks..."
  while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "APT lock detected. Waiting for 5 seconds..."
    sleep 5
  done
}

# Function to run a command with retries
run_with_retry() {
  local max_attempts=10
  local attempt=1
  until "$@"; do
    if [ $attempt -ge $max_attempts ]; then
      echo "Command failed after $attempt attempts."
      exit 1
    fi
    echo "Command failed. Attempt $attempt/$max_attempts. Retrying in 5 seconds..."
    attempt=$((attempt+1))
    sleep 5
    wait_for_apt_lock
  done
}

wait_for_apt_lock

echo "Updating package index..."
run_with_retry sudo apt-get update -y

echo "Installing required packages..."
run_with_retry sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release

echo "Adding Docker's official GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "Adding Docker repository..."
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package index again..."
run_with_retry sudo apt-get update -y

echo "Installing Docker Engine..."
run_with_retry sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo "Adding user to 'docker' group..."
sudo usermod -aG docker $USER

echo "Enabling Docker service to start on boot..."
sudo systemctl enable docker

echo "Starting Docker service..."
sudo systemctl start docker

echo "Docker installation completed successfully."
echo "Please log out and log back in to apply group changes."

sleep 10

echo "***** Application Deployment Started *******"
echo "Logging in to Docker Hub to pull the image"
echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin

echo "Login successful"
echo "Starting the container"
sudo docker run -it -d -p 5000:5000 "${DOCKER_USER}/paper_social:latest"
echo "Container started"

sleep 5
echo "*************** Container has been deployed, hit the URL to check **************"