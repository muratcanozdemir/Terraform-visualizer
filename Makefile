# Define variables
APP_NAME = terraform_state_visualizer
VERSION = 0.1
WHEEL_FILE = dist/$(APP_NAME)-$(VERSION)-py3-none-any.whl
DOCKER_IMAGE = $(APP_NAME)

.PHONY: all clean build wheel docker

# Default target
all: clean build

# Clean up build artifacts
clean:
	rm -rf build dist *.egg-info

# Build the wheel and sdist
build: wheel docker

# Build the wheel
wheel:
	python setup.py sdist bdist_wheel

# Build the Docker image
docker: 
	docker build -t $(DOCKER_IMAGE) .

# Install dependencies and run the application locally
run:
	uvicorn app:app --reload

# Install dependencies
install:
	pip install -r requirements.txt
